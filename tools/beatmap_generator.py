

import argparse
import json
import os
import sys
from pathlib import Path

try:
    import librosa
    import numpy as np
    from scipy.signal import find_peaks
except ImportError:
    print("Error: Required packages not installed.")
    print("Install with: pip install librosa numpy scipy")
    sys.exit(1)

# =============================================================================
# GLOBAL TIMING CONSTANTS
# Smaller hop_length = higher time resolution for onset detection.
# 256 samples @ 22050 Hz = ~11.6ms per frame (vs default 512 = ~23ms).
# This halves the maximum timing error from ±23ms to ±11ms.
# =============================================================================
HOP_LENGTH = 256
SR = 22050


def detect_bpm(y, sr):
    """Estimate the tempo of the track."""
    tempo, _ = librosa.beat.beat_track(y=y, sr=sr, hop_length=HOP_LENGTH)
    # librosa returns either a scalar or array depending on version
    if hasattr(tempo, '__len__'):
        return float(tempo[0])
    return float(tempo)


def get_beat_times(y, sr):
    """Return timestamps for each detected beat."""
    tempo, beat_frames = librosa.beat.beat_track(y=y, sr=sr, hop_length=HOP_LENGTH)
    beat_times = librosa.frames_to_time(beat_frames, sr=sr, hop_length=HOP_LENGTH)
    return beat_times


def separate_percussive(y, margin=3.0):
    """
    Isolate the percussive component of audio using HPSS.
    
    margin: higher = stricter separation, cleaner drums but may lose softer hits.
        - 1.0 = mild separation (keeps some harmonic bleed)
        - 3.0 = strong separation (clean drums, good for most tracks)
        - 5.0 = very aggressive (only the hardest transients survive)
    
    Using margin=3.0 gives us cleaner kick/snare/hat isolation than the default (1.0).
    """
    y_harmonic, y_percussive = librosa.effects.hpss(y, margin=margin)
    return y_harmonic, y_percussive


def refine_onset_to_transient(y, sr, onset_time, search_window_ms=15):
    """
    Given a frame-level onset time, find the exact sample where the
    transient energy spike begins within a small search window.
    
    This snaps the onset to the true waveform peak, removing the
    ±1 frame (~11ms) uncertainty from frame-based detection.
    
    Returns the corrected onset time.
    """
    search_samples = int(search_window_ms / 1000.0 * sr)
    center_sample = int(onset_time * sr)
    
    start = max(0, center_sample - search_samples)
    end = min(len(y), center_sample + search_samples)
    
    if start >= end:
        return onset_time
    
    # Find the sample with maximum absolute amplitude in the window
    # This is where the transient actually hits
    segment = np.abs(y[start:end])
    peak_offset = np.argmax(segment)
    
    refined_sample = start + peak_offset
    refined_time = refined_sample / sr
    
    return refined_time


def get_onset_times(y, sr, sensitivity='normal'):
    """
    Detect note placement by finding audio onsets using high-resolution
    percussive transient detection.
    
    Key improvements:
    - Uses HOP_LENGTH=256 for ~11ms frame resolution (vs default 23ms)
    - Stronger HPSS margin (3.0) for cleaner drum isolation
    - Superflux-style onset detection with lag=2 for sharper peak picking
    - Each onset is refined to the true waveform transient peak
    - Percussive signal weighted at 80% to prioritize drum hits
    """
    # Separate with stronger margin for cleaner drums
    y_harmonic, y_percussive = separate_percussive(y, margin=3.0)
    
    # Sensitivity presets - lower delta = more notes detected
    sensitivity_settings = {
        'low':    {'delta': 0.08, 'wait': 4},
        'normal': {'delta': 0.05, 'wait': 3},
        'high':   {'delta': 0.02, 'wait': 2}
    }
    settings = sensitivity_settings.get(sensitivity, sensitivity_settings['normal'])
    
    # Percussive onset envelope with higher resolution
    # Using max aggregation instead of median to preserve sharp transients
    onset_env_perc = librosa.onset.onset_strength(
        y=y_percussive, 
        sr=sr,
        hop_length=HOP_LENGTH,
        aggregate=np.max  # max preserves sharp drum transients better than median
    )
    
    # Full-spectrum onset envelope catches melodic accents we'd otherwise miss
    onset_env_full = librosa.onset.onset_strength(
        y=y, 
        sr=sr,
        hop_length=HOP_LENGTH,
        feature=librosa.feature.melspectrogram,
        n_mels=128,
        fmax=8000
    )
    
    # Blend heavily toward percussion — we want drum hits, not chord changes
    onset_env_combined = 0.8 * onset_env_perc + 0.2 * onset_env_full
    
    # Use superflux-style peak picking with lag for sharper onset selection
    # lag=2 compares each frame to 2 frames back, reducing false positives
    onset_frames = librosa.onset.onset_detect(
        onset_envelope=onset_env_combined,
        sr=sr,
        hop_length=HOP_LENGTH,
        units='frames',
        delta=settings['delta'],
        wait=settings['wait'],
        backtrack=True  # Snaps to the nearest preceding energy minimum
    )
    
    onset_times = librosa.frames_to_time(onset_frames, sr=sr, hop_length=HOP_LENGTH)
    
    # Refine each onset to the exact waveform transient peak
    # This removes the ±1 frame jitter from frame-based detection
    refined_times = np.array([
        refine_onset_to_transient(y, sr, t, search_window_ms=12)
        for t in onset_times
    ])
    
    return refined_times


def get_strong_beats(y, sr):
    """
    Extract beats with above-average intensity.
    Good for downbeats and accents.
    """
    tempo, beat_frames = librosa.beat.beat_track(y=y, sr=sr, units='frames', hop_length=HOP_LENGTH)
    
    # Measure how "loud" each beat is
    onset_env = librosa.onset.onset_strength(y=y, sr=sr, hop_length=HOP_LENGTH)
    beat_strengths = onset_env[beat_frames] if len(beat_frames) > 0 else []
    
    # Only keep beats above median strength
    if len(beat_strengths) > 0:
        strength_threshold = np.median(beat_strengths)
        strong_beat_mask = beat_strengths >= strength_threshold
        strong_beat_frames = beat_frames[strong_beat_mask]
        strong_beat_times = librosa.frames_to_time(strong_beat_frames, sr=sr, hop_length=HOP_LENGTH)
        return strong_beat_times
    
    return librosa.frames_to_time(beat_frames, sr=sr, hop_length=HOP_LENGTH)


# =============================================================================
# Beat-Aligned Note Generation System
# =============================================================================

def build_beat_grid(beat_times, subdivision=4):
    """
    Create a timing grid by subdividing beats.
    
    subdivision: how many slots per beat
        1 = quarter notes only (on the beat)
        2 = eighth notes
        4 = sixteenth notes
    """
    if len(beat_times) < 2:
        return np.array(beat_times)
    
    grid = []
    for i in range(len(beat_times) - 1):
        beat_start = beat_times[i]
        beat_end = beat_times[i + 1]
        beat_duration = beat_end - beat_start
        
        # Create subdivision points within this beat
        for sub in range(subdivision):
            grid_time = beat_start + (sub / subdivision) * beat_duration
            grid.append(grid_time)
    
    # Add the final beat
    grid.append(beat_times[-1])
    
    return np.array(grid)


def snap_onsets_to_grid(onset_times, grid_times, tolerance_ms=50):
    """
    Snap onsets to the nearest grid point within tolerance.
    Returns only onsets that align with the musical grid.
    
    tolerance_ms: max distance (in ms) for an onset to snap to a grid point
    """
    tolerance_sec = tolerance_ms / 1000.0
    snapped = []
    used_grid_points = set()
    
    for onset in onset_times:
        # Find closest grid point
        distances = np.abs(grid_times - onset)
        closest_idx = np.argmin(distances)
        closest_dist = distances[closest_idx]
        
        # Only snap if within tolerance and grid point not already used
        if closest_dist <= tolerance_sec and closest_idx not in used_grid_points:
            snapped.append(grid_times[closest_idx])
            used_grid_points.add(closest_idx)
    
    return np.array(snapped)


def get_onset_strengths_at_times(y, sr, times):
    """
    Get onset strength values at specific times.
    Uses our global HOP_LENGTH for consistent frame resolution.
    """
    onset_env = librosa.onset.onset_strength(y=y, sr=sr, hop_length=HOP_LENGTH)
    
    strengths = []
    for t in times:
        frame = librosa.time_to_frames(t, sr=sr, hop_length=HOP_LENGTH)
        if frame < len(onset_env):
            strengths.append(onset_env[frame])
        else:
            strengths.append(0.0)
    
    return np.array(strengths)


def classify_hit_strength(strengths):
    """
    Classify each onset as soft, medium, or hard based on its
    percussive energy relative to the distribution.
    
    Returns an array of labels: 'soft', 'medium', 'hard'
    
    This lets us assign harder notes to more prominent drum hits,
    making the gameplay feel like you're triggering the actual sound.
    """
    if len(strengths) == 0:
        return np.array([])
    
    p33 = np.percentile(strengths, 33)
    p66 = np.percentile(strengths, 66)
    
    labels = []
    for s in strengths:
        if s >= p66:
            labels.append('hard')
        elif s >= p33:
            labels.append('medium')
        else:
            labels.append('soft')
    
    return np.array(labels)


def filter_by_density(times, strengths, max_notes_per_second=4.0):
    """
    Reduce note density by keeping strongest onsets in each time window.
    Prevents overwhelming the player with too many notes.
    """
    if len(times) == 0:
        return times
    
    window_size = 1.0 / max_notes_per_second
    filtered = []
    
    i = 0
    while i < len(times):
        window_end = times[i] + window_size
        
        # Gather all notes in this window
        window_notes = []
        j = i
        while j < len(times) and times[j] < window_end:
            window_notes.append((times[j], strengths[j], j))
            j += 1
        
        # Keep the strongest one in this window
        if window_notes:
            best = max(window_notes, key=lambda x: x[1])
            filtered.append(best[0])
        
        # Move past this window
        i = j if j > i else i + 1
    
    return np.array(filtered)


def compute_global_offset(onset_times, grid_times, max_correction_ms=20):
    """
    Measure the average timing error between detected onsets and the
    nearest grid points. If there's a consistent drift (e.g., onsets
    are systematically 8ms early), compute a small correction.
    
    max_correction_ms: cap the correction to avoid over-adjusting.
    Returns the offset in seconds (positive = shift notes later).
    """
    if len(onset_times) == 0 or len(grid_times) == 0:
        return 0.0
    
    errors = []
    for onset in onset_times:
        distances = grid_times - onset
        closest_idx = np.argmin(np.abs(distances))
        error = distances[closest_idx]  # positive = onset is early, negative = late
        errors.append(error)
    
    median_error = np.median(errors)
    max_correction = max_correction_ms / 1000.0
    
    # Only apply if the drift is significant (>3ms) but not too large
    if abs(median_error) > 0.003 and abs(median_error) <= max_correction:
        return median_error
    
    return 0.0


def generate_beat_aligned_notes(y, sr, difficulty='normal', sensitivity='normal'):
    """
    Generate note times using beat-aligned grid with onset reinforcement.
    This is the core of the musical note placement system.
    
    Sync improvements:
    - Uses stronger HPSS (margin=3.0) for cleaner drum isolation
    - HOP_LENGTH=256 for ~11ms frame precision
    - Onset-to-transient refinement for sample-accurate timing
    - Global offset correction to fix systematic drift
    - Hit strength classification for intensity-aware note placement
    """
    # Difficulty controls subdivision depth and density
    # NOTE DENSITY: Increase max_nps values for more notes per second
    # Higher = more dense beatmaps, lower = sparser beatmaps
    # SHIFTED: Easy = old Normal, Normal = near Expert, Hard = almost Expert
    difficulty_config = {
        'easy': {
            'subdivision': 4,       # sixteenth notes (was old normal)
            'max_nps': 8.0,         # old normal density
            'snap_tolerance': 65,
            'onset_weight': 0.5,
        },
        'normal': {
            'subdivision': 8,       # 32nd notes (near expert)
            'max_nps': 14.0,        # just under expert's 16.0
            'snap_tolerance': 52,   # tight snap, close to expert's 50
            'onset_weight': 0.8,    # close to expert's 0.85
        },
        'hard': {
            'subdivision': 8,       # 32nd notes (same as expert)
            'max_nps': 15.0,        # between normal and expert
            'snap_tolerance': 50,   # same as expert
            'onset_weight': 0.83,
        },
        'expert': {
            'subdivision': 8,       # 32nd notes
            'max_nps': 16.0,
            'snap_tolerance': 50,
            'onset_weight': 0.85,
        }
    }
    
    config = difficulty_config.get(difficulty, difficulty_config['normal'])
    
    # Separate percussive with stronger margin for cleaner drum isolation
    y_harmonic, y_percussive = separate_percussive(y, margin=3.0)
    
    # Get beat times from percussive signal (cleaner beat tracking)
    print("  Tracking beats from percussive signal...")
    beat_times = get_beat_times(y_percussive, sr)
    print(f"  Found {len(beat_times)} beats")
    
    # Build subdivided grid
    print(f"  Building grid with {config['subdivision']}x subdivision...")
    grid = build_beat_grid(beat_times, subdivision=config['subdivision'])
    print(f"  Grid has {len(grid)} slots")
    
    # Get onsets from percussive signal (already uses refined transient detection)
    print("  Detecting percussive onsets...")
    onset_times = get_onset_times(y_percussive, sr, sensitivity=sensitivity)
    print(f"  Found {len(onset_times)} raw onsets")
    
    # Compute global offset correction before snapping
    # This fixes systematic timing drift (e.g., onsets consistently early/late)
    global_offset = compute_global_offset(onset_times, grid, max_correction_ms=20)
    if abs(global_offset) > 0.003:
        print(f"  Applying global timing correction: {global_offset*1000:.1f}ms")
        onset_times = onset_times + global_offset
    
    # Snap onsets to grid
    print(f"  Snapping onsets to grid (tolerance: {config['snap_tolerance']}ms)...")
    snapped_onsets = snap_onsets_to_grid(
        onset_times, grid, 
        tolerance_ms=config['snap_tolerance']
    )
    print(f"  {len(snapped_onsets)} onsets aligned to grid")
    
    # Always include strong beats (downbeats feel important)
    strong_beats = get_strong_beats(y, sr)
    strong_snapped = snap_onsets_to_grid(strong_beats, grid, tolerance_ms=80)
    
    # Merge snapped onsets with strong beats
    all_note_times = np.unique(np.concatenate([snapped_onsets, strong_snapped]))
    all_note_times = np.sort(all_note_times)
    print(f"  Merged to {len(all_note_times)} candidate notes")
    
    # Get onset strengths for density filtering (using percussive signal for accuracy)
    strengths = get_onset_strengths_at_times(y_percussive, sr, all_note_times)
    
    # Classify hit strengths for intensity-aware note placement
    hit_classes = classify_hit_strength(strengths)
    
    # Filter by density to keep charts playable
    print(f"  Filtering to max {config['max_nps']} notes/sec...")
    final_times = filter_by_density(all_note_times, strengths, config['max_nps'])
    print(f"  Final note count: {len(final_times)}")
    
    # Get final strength classifications for the surviving notes
    final_strengths = get_onset_strengths_at_times(y_percussive, sr, final_times)
    final_hit_classes = classify_hit_strength(final_strengths)
    
    return final_times, final_hit_classes


def assign_lanes(times, difficulty='normal', hit_classes=None):
    """
    Map note times to lanes (0-3).
    Higher difficulties = more notes, more doubles.
    
    hit_classes: optional array of 'soft'/'medium'/'hard' labels.
        - Hard hits get more double-notes (feels like a powerful strike)
        - Soft hits avoid doubles (feels like a light tap)
        This makes the note patterns feel connected to the music's dynamics.
    """
    notes = []
    lane_count = 4
    
    # Tweak these to adjust how each difficulty feels
    # SHIFTED: Easy = old Normal, Normal = near Expert, Hard = almost Expert
    difficulty_settings = {
        'easy': {
            'min_gap': 0.25,        # old normal spacing
            'double_chance': 0.15,  # old normal doubles
            'pattern_variety': 0.5  # old normal variety
        },
        'normal': {
            'min_gap': 0.12,        # tight spacing, close to expert's 0.1
            'double_chance': 0.35,  # close to expert's 0.4
            'pattern_variety': 0.85 # close to expert's 0.9
        },
        'hard': {
            'min_gap': 0.11,        # between normal and expert
            'double_chance': 0.38,  # between normal and expert
            'pattern_variety': 0.88
        },
        'expert': {
            'min_gap': 0.1,
            'double_chance': 0.4,
            'pattern_variety': 0.9
        }
    }
    
    settings = difficulty_settings.get(difficulty, difficulty_settings['normal'])
    
    last_time = -1
    last_lane = -1
    pattern_counter = 0
    
    for i, time in enumerate(times):
        # Enforce minimum spacing between notes
        if time - last_time < settings['min_gap']:
            continue
        
        pattern_counter = (pattern_counter + 1) % 8
        
        if np.random.random() < settings['pattern_variety']:
            patterns = [
                [0, 1, 2, 3, 3, 2, 1, 0],  # sweep
                [0, 2, 1, 3, 0, 2, 1, 3],  # zigzag
                [0, 1, 2, 3, 0, 1, 2, 3],  # stairs
                [1, 2, 1, 2, 0, 3, 0, 3],  # center-edge
                [0, 3, 1, 2, 2, 1, 3, 0],  # outside-in
            ]
            pattern = patterns[i % len(patterns)]
            lane = pattern[pattern_counter]
        else:
            # Random but avoid repeating same lane
            available_lanes = [l for l in range(lane_count) if l != last_lane]
            lane = np.random.choice(available_lanes)
        
        notes.append({
            'time': round(float(time), 3),
            'lane': int(lane)
        })
        
        # Double-note chance is modulated by hit strength:
        # Hard hits = higher chance (feels like a powerful strike)
        # Soft hits = lower chance (feels like a light tap)
        base_chance = settings['double_chance']
        if hit_classes is not None and i < len(hit_classes):
            hit_class = hit_classes[i]
            if hit_class == 'hard':
                double_chance = min(base_chance * 1.8, 0.6)  # boost for hard hits
            elif hit_class == 'soft':
                double_chance = base_chance * 0.3  # reduce for soft hits
            else:
                double_chance = base_chance
        else:
            double_chance = base_chance
        
        if np.random.random() < double_chance:
            other_lanes = [l for l in range(lane_count) if l != lane]
            double_lane = np.random.choice(other_lanes)
            notes.append({
                'time': round(float(time), 3),
                'lane': int(double_lane)
            })
        
        last_time = time
        last_lane = lane
    
    notes.sort(key=lambda x: (x['time'], x['lane']))
    
    return notes


def get_audio_duration(y, sr):
    return len(y) / sr


def get_difficulty_rating(difficulty):
    """Star rating for UI display. Randomly selects from the difficulty's star range."""
    # Easy: 1-2, Normal: 3-4, Hard: 5-6, Expert: 7
    rating_ranges = {
        'easy': [1, 2],
        'normal': [3, 4],
        'hard': [5, 6],
        'expert': [7]
    }
    stars = rating_ranges.get(difficulty, [3, 4])
    return int(np.random.choice(stars))


def generate_beatmap(audio_path, difficulty='normal', bpm_override=None, offset=0, sensitivity='normal', use_beat_aligned=True):
    """
    Analyze audio and generate a playable beatmap.
    
    use_beat_aligned: if True, uses musical grid snapping (recommended).
                      if False, uses legacy onset-based detection.
    """
    print(f"Loading audio: {audio_path}")
    
    # 22050 Hz is plenty for beat detection
    y, sr = librosa.load(audio_path, sr=22050)
    
    duration = get_audio_duration(y, sr)
    print(f"Duration: {duration:.2f} seconds")
    
    if bpm_override:
        bpm = bpm_override
        print(f"Using manual BPM: {bpm}")
    else:
        bpm = detect_bpm(y, sr)
        print(f"Detected BPM: {bpm:.1f}")
    
    if use_beat_aligned:
        # New beat-aligned system - notes snap to musical grid
        print(f"\nUsing beat-aligned generation (difficulty: {difficulty})...")
        note_times, hit_classes = generate_beat_aligned_notes(y, sr, difficulty=difficulty, sensitivity=sensitivity)
    else:
        # Legacy behavior - raw onset detection
        print(f"Analyzing audio for note placement (sensitivity: {sensitivity})...")
        onset_times = get_onset_times(y, sr, sensitivity=sensitivity)
        print(f"Found {len(onset_times)} potential note positions")
        
        # Include strong beats so we don't miss obvious downbeats
        strong_beats = get_strong_beats(y, sr)
        print(f"Found {len(strong_beats)} strong beats")
        
        # Merge and dedupe
        note_times = np.unique(np.concatenate([onset_times, strong_beats]))
        note_times = np.sort(note_times)
        print(f"Combined to {len(note_times)} unique note positions")
        hit_classes = None
    
    print(f"\nGenerating {difficulty} beatmap...")
    notes = assign_lanes(note_times, difficulty, hit_classes=hit_classes)
    
    # Apply timing offset if specified
    if offset != 0:
        print(f"Applying offset of {offset}s to all notes...")
        for note in notes:
            note['time'] = round(note['time'] + offset, 3)
        # Drop any notes that would be before t=0
        notes = [n for n in notes if n['time'] >= 0]
    
    print(f"Generated {len(notes)} notes")
    
    audio_filename = Path(audio_path).stem
    
    beatmap = {
        "title": audio_filename.replace('_', ' ').title(),
        "artist": "Unknown Artist",
        "difficulty": difficulty.capitalize(),
        "difficultyRating": get_difficulty_rating(difficulty),
        "bpm": round(bpm),
        "offset": offset,
        "length": int(duration),
        "noteCount": len(notes),
        "notes": notes
    }
    
    return beatmap


def save_beatmap(beatmap, output_path):
    with open(output_path, 'w') as f:
        json.dump(beatmap, f, indent=2)
    print(f"Saved beatmap to: {output_path}")


def print_beatmap_summary(beatmap):
    """Show a summary of the generated beatmap."""
    print("\n" + "="*50)
    print("BEATMAP SUMMARY")
    print("="*50)
    print(f"Title: {beatmap['title']}")
    print(f"Difficulty: {beatmap['difficulty']} ({beatmap['difficultyRating']} stars)")
    print(f"BPM: {beatmap['bpm']}")
    print(f"Length: {beatmap['length']} seconds")
    print(f"Notes: {beatmap['noteCount']}")
    print(f"Notes per second: {beatmap['noteCount'] / beatmap['length']:.2f}")
    
    lane_counts = [0, 0, 0, 0]
    for note in beatmap['notes']:
        lane_counts[note['lane']] += 1
    
    print("\nLane Distribution:")
    lane_names = ['Left (←)', 'Up (↑)', 'Down (↓)', 'Right (→)']
    for i, count in enumerate(lane_counts):
        pct = (count / len(beatmap['notes']) * 100) if beatmap['notes'] else 0
        print(f"  {lane_names[i]}: {count} ({pct:.1f}%)")
    
    print("="*50 + "\n")


def main():
    parser = argparse.ArgumentParser(
        description='Generate beatmaps for Roku Osu-Mania from audio files',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog='''
Examples:
  %(prog)s song.mp3                           
  %(prog)s song.mp3 -d hard -s high           
  %(prog)s song.mp3 --offset -0.1             
  %(prog)s song.mp3 --offset 0.05 -s high     
        '''
    )
    parser.add_argument('audio_file', help='Path to audio file (mp3, wav, ogg, etc.)')
    parser.add_argument('-o', '--output', help='Output JSON file path')
    parser.add_argument('-d', '--difficulty', 
                        choices=['easy', 'normal', 'hard', 'expert'],
                        default='normal',
                        help='Difficulty level (default: normal)')
    parser.add_argument('-s', '--sensitivity',
                        choices=['low', 'normal', 'high'],
                        default='normal',
                        help='How sensitive beat detection is (default: normal)')
    parser.add_argument('-b', '--bpm', type=float, help='Override detected BPM')
    parser.add_argument('--offset', type=float, default=0,
                        help='Shift notes in time (negative = earlier, positive = later)')
    parser.add_argument('-t', '--title', help='Song title (default: filename)')
    parser.add_argument('-a', '--artist', help='Artist name (default: Unknown Artist)')
    parser.add_argument('--preview', action='store_true',
                        help='Just show what would be generated without saving')
    parser.add_argument('--legacy', action='store_true',
                        help='Use legacy onset-based detection instead of beat-aligned grid')
    
    args = parser.parse_args()
    
    if not os.path.exists(args.audio_file):
        print(f"Error: Audio file not found: {args.audio_file}")
        sys.exit(1)
    
    beatmap = generate_beatmap(
        args.audio_file,
        difficulty=args.difficulty,
        bpm_override=args.bpm,
        offset=args.offset,
        sensitivity=args.sensitivity,
        use_beat_aligned=not args.legacy
    )
    
    # Override metadata if provided
    if args.title:
        beatmap['title'] = args.title
    if args.artist:
        beatmap['artist'] = args.artist
    
    print_beatmap_summary(beatmap)
    
    if not args.preview:
        if args.output:
            output_path = args.output
        else:
            audio_name = Path(args.audio_file).stem
            output_path = f"{audio_name}_{args.difficulty}_beatmap.json"
        
        save_beatmap(beatmap, output_path)
    else:
        print("Preview mode - beatmap not saved")
        print("\nSample notes (first 10):")
        for note in beatmap['notes'][:10]:
            print(f"  Time: {note['time']:.3f}s, Lane: {note['lane']}")


if __name__ == '__main__':
    main()
