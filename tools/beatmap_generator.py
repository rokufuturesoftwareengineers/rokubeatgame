#!/usr/bin/env python3
"""
Beatmap generator - turns audio files into playable beatmaps.
Uses librosa for beat/onset detection.

Usage:
    python beatmap_generator.py <audio_file> [options]

Options:
    --output, -o     Output path (default: <audio_name>_beatmap.json)
    --difficulty, -d easy/normal/hard/expert (default: normal)
    --bpm, -b        Manual BPM if auto-detect is wrong
    --offset         Sync offset in seconds
    --preview        Just show stats, don't save
"""

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
    """Tempo detection via librosa."""
    tempo, _ = librosa.beat.beat_track(y=y, sr=sr)
    # librosa sometimes returns array, sometimes scalar
    if hasattr(tempo, '__len__'):
        return float(tempo[0])
    return float(tempo)


def get_beat_times(y, sr):
    """Beat timestamps."""
    tempo, beat_frames = librosa.beat.beat_track(y=y, sr=sr)
    beat_times = librosa.frames_to_time(beat_frames, sr=sr)
    return beat_times


def get_onset_times(y, sr):
    """Where the notes should go - uses onset detection."""
    onset_frames = librosa.onset.onset_detect(y=y, sr=sr, units='frames')
    onset_times = librosa.frames_to_time(onset_frames, sr=sr)
    return onset_times


def assign_lanes(times, difficulty='normal'):
    """
    Maps detected notes to 4 lanes.
    Higher difficulty = denser patterns, more chords.
    """
    notes = []
    lane_count = 4
    
    # Difficulty settings
    difficulty_settings = {
        'easy': {
            'min_gap': 0.4,      # Minimum time between notes
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
        # Too close to previous note
        if time - last_time < settings['min_gap']:
            continue
        
        pattern_counter = (pattern_counter + 1) % 8
        
        if np.random.random() < settings['pattern_variety']:
            # Use predefined patterns for a more musical feel
            patterns = [
                [0, 1, 2, 3, 3, 2, 1, 0],  # Wave
                [0, 2, 1, 3, 0, 2, 1, 3],  # Alternating pairs
                [0, 1, 2, 3, 0, 1, 2, 3],  # Sequential
                [1, 2, 1, 2, 0, 3, 0, 3],  # Center-outer
                [0, 3, 1, 2, 2, 1, 3, 0],  # Mirror
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
        
        # Maybe add a second note (chord)
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
    """Star rating for the difficulty picker."""
    ratings = {
        'easy': 2,
        'normal': 4,
        'hard': 5,
        'expert': 7
    }
    return ratings.get(difficulty, 4)


def generate_beatmap(audio_path, difficulty='normal', bpm_override=None, offset=0):
    """Main entry point - loads audio and spits out a beatmap dict."""
    print(f"Loading audio: {audio_path}")
    
    # Load audio
    y, sr = librosa.load(audio_path, sr=22050)
    
    duration = get_audio_duration(y, sr)
    print(f"Duration: {duration:.2f} seconds")
    
    if bpm_override:
        bpm = bpm_override
        print(f"Using manual BPM: {bpm}")
    else:
        bpm = detect_bpm(y, sr)
        print(f"Detected BPM: {bpm:.1f}")
    
    print("Analyzing audio for note placement...")
    onset_times = get_onset_times(y, sr)
    print(f"Found {len(onset_times)} potential note positions")
    
    print(f"Generating {difficulty} beatmap...")
    notes = assign_lanes(onset_times, difficulty)
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
    """Shows what we generated."""
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
        description='Generate beatmaps for Roku Osu-Mania from audio files'
    )
    parser.add_argument('audio_file', help='Path to audio file (mp3, wav, ogg, etc.)')
    parser.add_argument('-o', '--output', help='Output JSON file path')
    parser.add_argument('-d', '--difficulty', 
                        choices=['easy', 'normal', 'hard', 'expert'],
                        default='normal',
                        help='Difficulty level (default: normal)')
    parser.add_argument('-b', '--bpm', type=float, help='Override detected BPM')
    parser.add_argument('--offset', type=float, default=0,
                        help='Audio offset in seconds (default: 0)')
    parser.add_argument('--preview', action='store_true',
                        help='Preview only, do not save file')
    
    args = parser.parse_args()
    
    # Validate input file
    if not os.path.exists(args.audio_file):
        print(f"Error: Audio file not found: {args.audio_file}")
        sys.exit(1)
    
    # Generate beatmap
    beatmap = generate_beatmap(
        args.audio_file,
        difficulty=args.difficulty,
        bpm_override=args.bpm,
        offset=args.offset
    )
    
    # Print summary
    print_beatmap_summary(beatmap)
    
    # Save if not preview
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
