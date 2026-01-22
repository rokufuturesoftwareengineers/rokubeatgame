

import argparse
import json
import os
import sys
from pathlib import Path

try:
    import librosa
    import numpy as np
except ImportError:
    print("Error: Required packages not installed.")
    print("Install with: pip install librosa numpy")
    sys.exit(1)


def detect_bpm(y, sr):
    """Estimate the tempo of the track."""
    tempo, _ = librosa.beat.beat_track(y=y, sr=sr)
    # librosa returns either a scalar or array depending on version
    if hasattr(tempo, '__len__'):
        return float(tempo[0])
    return float(tempo)


def get_beat_times(y, sr):
    """Return timestamps for each detected beat."""
    tempo, beat_frames = librosa.beat.beat_track(y=y, sr=sr)
    beat_times = librosa.frames_to_time(beat_frames, sr=sr)
    return beat_times


def get_onset_times(y, sr, sensitivity='normal'):
    """
    Detect note placement by finding audio onsets.
    Focuses on percussive hits since those feel best to tap to.
    """
    # Separate harmonic and percussive - we care more about the drums
    y_harmonic, y_percussive = librosa.effects.hpss(y)
    
    # Sensitivity presets - lower delta = more notes detected
    sensitivity_settings = {
        'low': {'delta': 0.1, 'wait': 5},
        'normal': {'delta': 0.07, 'wait': 3},
        'high': {'delta': 0.03, 'wait': 2}
    }
    settings = sensitivity_settings.get(sensitivity, sensitivity_settings['normal'])
    
    # Percussive onsets give us the "hits"
    onset_env_perc = librosa.onset.onset_strength(
        y=y_percussive, 
        sr=sr,
        aggregate=np.median  # Median reduces noise spikes
    )
    
    # Full audio catches melodic stuff we'd otherwise miss
    onset_env_full = librosa.onset.onset_strength(
        y=y, 
        sr=sr,
        feature=librosa.feature.melspectrogram,
        n_mels=128,
        fmax=8000
    )
    
    # Blend them, favoring percussion
    onset_env_combined = 0.7 * onset_env_perc + 0.3 * onset_env_full
    
    # Pick out the actual onset times
    onset_frames = librosa.onset.onset_detect(
        onset_envelope=onset_env_combined,
        sr=sr,
        units='frames',
        delta=settings['delta'],
        wait=settings['wait'],
        backtrack=True  # Snaps to the true start of the sound
    )
    
    onset_times = librosa.frames_to_time(onset_frames, sr=sr)
    
    return onset_times


def get_strong_beats(y, sr):
    """
    Extract beats with above-average intensity.
    Good for downbeats and accents.
    """
    tempo, beat_frames = librosa.beat.beat_track(y=y, sr=sr, units='frames')
    
    # Measure how "loud" each beat is
    onset_env = librosa.onset.onset_strength(y=y, sr=sr)
    beat_strengths = onset_env[beat_frames] if len(beat_frames) > 0 else []
    
    # Only keep beats above median strength
    if len(beat_strengths) > 0:
        strength_threshold = np.median(beat_strengths)
        strong_beat_mask = beat_strengths >= strength_threshold
        strong_beat_frames = beat_frames[strong_beat_mask]
        strong_beat_times = librosa.frames_to_time(strong_beat_frames, sr=sr)
        return strong_beat_times
    
    return librosa.frames_to_time(beat_frames, sr=sr)


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
    Useful for weighting which notes to keep.
    """
    onset_env = librosa.onset.onset_strength(y=y, sr=sr)
    hop_length = 512  # librosa default
    
    strengths = []
    for t in times:
        frame = librosa.time_to_frames(t, sr=sr, hop_length=hop_length)
        if frame < len(onset_env):
            strengths.append(onset_env[frame])
        else:
            strengths.append(0.0)
    
    return np.array(strengths)


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


def generate_beat_aligned_notes(y, sr, difficulty='normal', sensitivity='normal'):
    """
    Generate note times using beat-aligned grid with onset reinforcement.
    This is the core of the musical note placement system.
    """
    # Difficulty controls subdivision depth and density
    # Tuned for ~65% more notes than original sparse settings
    difficulty_config = {
        'easy': {
            'subdivision': 2,       # eighth notes (was quarter)
            'max_nps': 3.3,         # notes per second cap (was 2.0)
            'snap_tolerance': 75,   # looser snap to catch more (was 60)
            'onset_weight': 0.3,
        },
        'normal': {
            'subdivision': 4,       # sixteenth notes (was eighth)
            'max_nps': 5.8,         # was 3.5
            'snap_tolerance': 65,   # was 50
            'onset_weight': 0.5,
        },
        'hard': {
            'subdivision': 4,       # sixteenth notes
            'max_nps': 8.25,        # was 5.0
            'snap_tolerance': 55,   # was 40
            'onset_weight': 0.7, 
        },
        'expert': {
            'subdivision': 8,       # 32nd notes (was sixteenth)
            'max_nps': 13.2,        # was 8.0
            'snap_tolerance': 50,   # was 35
            'onset_weight': 0.85,
        }
    }
    
    config = difficulty_config.get(difficulty, difficulty_config['normal'])
    
    # Separate percussive component for cleaner rhythm detection
    y_harmonic, y_percussive = librosa.effects.hpss(y)
    
    # Get beat times from percussive signal (cleaner beat tracking)
    print("  Tracking beats from percussive signal...")
    beat_times = get_beat_times(y_percussive, sr)
    print(f"  Found {len(beat_times)} beats")
    
    # Build subdivided grid
    print(f"  Building grid with {config['subdivision']}x subdivision...")
    grid = build_beat_grid(beat_times, subdivision=config['subdivision'])
    print(f"  Grid has {len(grid)} slots")
    
    # Get onsets from percussive signal
    print("  Detecting percussive onsets...")
    onset_times = get_onset_times(y_percussive, sr, sensitivity=sensitivity)
    print(f"  Found {len(onset_times)} raw onsets")
    
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
    
    # Get onset strengths for density filtering
    strengths = get_onset_strengths_at_times(y, sr, all_note_times)
    
    # Filter by density to keep charts playable
    print(f"  Filtering to max {config['max_nps']} notes/sec...")
    final_times = filter_by_density(all_note_times, strengths, config['max_nps'])
    print(f"  Final note count: {len(final_times)}")
    
    return final_times


def assign_lanes(times, difficulty='normal'):
    """
    Map note times to lanes (0-3).
    Higher difficulties = more notes, more doubles.
    """
    notes = []
    lane_count = 4
    
    # Tweak these to adjust how each difficulty feels
    difficulty_settings = {
        'easy': {
            'min_gap': 0.4,
            'double_chance': 0.05,
            'pattern_variety': 0.3
        },
        'normal': {
            'min_gap': 0.25,
            'double_chance': 0.15,
            'pattern_variety': 0.5
        },
        'hard': {
            'min_gap': 0.15,
            'double_chance': 0.25,
            'pattern_variety': 0.7
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
        
        # Occasionally add a double-note for variety
        if np.random.random() < settings['double_chance']:
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
    """Star rating for UI display."""
    ratings = {
        'easy': 2,
        'normal': 4,
        'hard': 5,
        'expert': 7
    }
    return ratings.get(difficulty, 4)


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
        note_times = generate_beat_aligned_notes(y, sr, difficulty=difficulty, sensitivity=sensitivity)
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
    
    print(f"\nGenerating {difficulty} beatmap...")
    notes = assign_lanes(note_times, difficulty)
    
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
