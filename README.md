# Roku Osu-Mania 🎵

A fully playable 4-key rhythm game (Osu-Mania style) for Roku devices, built with BrightScript and SceneGraph.

## ✨ Features

- **4-Key Mania Gameplay**: Left (←), Up (↑), Down (↓), Right (→)
- **Timing Windows**: PERFECT (±50ms, 300pts) and GOOD (±100ms, 100pts)
- **Combo System**: Score multiplier that builds with consecutive hits
- **Grade System**: S / A / B / C / D / F based on accuracy
- **High Score Tracking**: Persistent scores saved per song
- **Python Beatmap Generator**: Create beatmaps from any audio file using librosa

## 🎮 Controls

| Button | Action |
|--------|--------|
| ← Left | Lane 0 (leftmost) |
| ↑ Up | Lane 1 |
| ↓ Down | Lane 2 |
| → Right | Lane 3 (rightmost) |
| OK | Select / Pause |
| Back | Back / Quit |





---

## 🎮 Controls

| Button | Lane | Action |
|--------|------|--------|
| ← Left | 0 | Hit lane 0 (Red) |
| ↑ Up | 1 | Hit lane 1 (Blue) |
| ↓ Down | 2 | Hit lane 2 (Green) |
| → Right | 3 | Hit lane 3 (Orange) |
| OK | - | Select / Pause |
| Back | - | Back / Quit |

---

## 🎯 Scoring System

### Hit Windows
| Rating | Time Window | Points |
|--------|-------------|--------|
| PERFECT | ±50ms | 300 |
| GOOD | ±100ms | 100 |
| MISS | >100ms | 0 |

### Accuracy Formula
```
accuracy = (perfect + good × 0.7) / totalNotes × 100%
```

### Grade Thresholds
| Grade | Accuracy |
|-------|----------|
| S | ≥ 95% |
| A | ≥ 90% |
| B | ≥ 80% |
| C | ≥ 70% |
| D | ≥ 60% |
| F | < 60% |

---

## 🛠️ Beatmap Generation

### Prerequisites
```bash
cd tools
pip install -r requirements.txt
```

### Generate Beatmap from Audio
```bash
# Single file
python beatmap_generator.py song.mp3 -o song.json -d normal

# With metadata
python beatmap_generator.py song.mp3 -t "Song Title" -a "Artist" -d hard

# Batch process directory
python beatmap_generator.py --batch ./songs/ -o ./beatmaps/

# All difficulty levels
python beatmap_generator.py song.mp3 --all-difficulties
```

### Difficulty Levels
| Level | Stars | Description |
|-------|-------|-------------|
| Easy | ★★☆☆☆ | Beat-aligned, simple patterns |
| Normal | ★★★☆☆ | More frequent notes |
| Hard | ★★★★★ | Onset detection enabled |
| Expert | ★★★★★★★ | Dense patterns with doubles |

---

## 📦 Adding Songs

1. **Generate beatmap**:
   ```bash
   python tools/beatmap_generator.py your_song.mp3 -t "Song Name" -a "Artist"
   ```

2. **Copy files** to `assets/songs/`:
   ```
   assets/songs/your_song.mp3
   assets/songs/your_song.json
   ```

3. **Update `song_index.json`**:
   ```json
   {
     "songs": [
       {
         "id": "your_song",
         "title": "Song Name",
         "artist": "Artist",
         "difficulty": "Normal",
         "difficultyRating": 4,
         "length": 180,
         "beatmap": "your_song.json",
         "audio": "your_song.mp3"
       }
     ]
   }
   ```

---

## 🚀 Running the App

### VS Code (Recommended)
1. Install the **BrightScript Language** extension
2. Configure your Roku device IP in `.vscode/launch.json`
3. Enable Developer Mode on your Roku
4. Press **F5** or use **Run → Start Debugging**

### Manual Deployment
1. Zip the project (excluding `tools/` folder)
2. Enable Developer Mode on Roku (Home 3×, Up 2×, Right, Left, Right, Left, Right)
3. Go to `http://<roku-ip>` in your browser
4. Upload the zip file

---

## 📐 Technical Details

### Game Loop (60 FPS)
```brightscript
sub onGameLoop()
    currentTime = getCurrentSongTime()
    spawnNotes(currentTime)      ' Spawn notes based on scroll duration
    updateNotes(currentTime)     ' Move notes down lanes
    checkMissedNotes(currentTime) ' Auto-miss passed notes
    updateProgress(currentTime)  ' Update progress bar
end sub
```

### State Flow
```
START_MENU → SONG_SELECT → PLAYING → RESULTS
     ↑                                   ↓
     ←──────────── (retry) ──────────────┘
     ←────────── (song select) ──────────┘
```

---


