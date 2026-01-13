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

## 📁 Project Structure

```
roku_osu_mania/
├── manifest                     # Roku app configuration
├── source/
│   └── Main.brs                # App entry point
├── components/
│   ├── MainScene.xml/brs       # Central state controller
│   └── screens/
│       ├── StartMenu.xml/brs   # Main menu
│       ├── SongSelect.xml/brs  # Song selection
│       ├── GameplayScene.xml/brs # Core gameplay
│       └── ResultsScreen.xml/brs # Results display
├── assets/
│   └── songs/
│       ├── song_index.json     # Song catalog
│       └── <song_id>/          # Per-song folders
│           ├── beatmap.json    # Note timing data
│           ├── audio.mp3       # Song audio
│           └── cover.png       # Album art (optional)
├── images/                      # App icons and splash screens
└── tools/
    └── beatmap_generator.py    # Python beatmap generator
```

---

## 🖼️ PLACEHOLDER IMAGES - REPLACE THESE!

The `images/` folder contains **placeholder images** that need to be replaced with proper graphics.

### Required Images

| Filename | Dimensions | Purpose |
|----------|------------|---------|
| `icon_focus_hd.png` | **336 × 210** px | HD app icon (focused state) |
| `icon_focus_sd.png` | **246 × 140** px | SD app icon (focused state) |
| `icon_side_hd.png` | **108 × 69** px | HD app icon (side/unfocused) |
| `icon_side_sd.png` | **108 × 69** px | SD app icon (side/unfocused) |
| `splash_hd.png` | **1280 × 720** px | HD splash/loading screen |
| `splash_sd.png` | **720 × 480** px | SD splash/loading screen |

### Design Recommendations

- **Brand Color**: `#6c5ce7` (Purple)
- **Background**: `#1a1a2e` (Dark blue)
- **Include**: Game title "ROKU OSU-MANIA" or "ROKU BEAT"
- **Style**: Musical notes (♪ ♫), rhythm game aesthetic
- **Format**: PNG with transparency (optional)

### Quick Generation (ImageMagick)

```bash
# Install ImageMagick first: brew install imagemagick

# HD Focus Icon (336x210)
convert -size 336x210 xc:'#6c5ce7' \
  -font Arial-Bold -pointsize 28 -fill white \
  -gravity center -annotate 0 'ROKU\nOSU-MANIA' \
  images/icon_focus_hd.png

# SD Focus Icon (246x140)
convert -size 246x140 xc:'#6c5ce7' \
  -font Arial-Bold -pointsize 20 -fill white \
  -gravity center -annotate 0 'ROKU\nOSU-MANIA' \
  images/icon_focus_sd.png

# HD Side Icon (108x69)
convert -size 108x69 xc:'#6c5ce7' \
  -font Arial-Bold -pointsize 12 -fill white \
  -gravity center -annotate 0 'OSU' \
  images/icon_side_hd.png

# SD Side Icon (108x69)
convert -size 108x69 xc:'#6c5ce7' \
  -font Arial-Bold -pointsize 12 -fill white \
  -gravity center -annotate 0 'OSU' \
  images/icon_side_sd.png

# HD Splash (1280x720)
convert -size 1280x720 xc:'#1a1a2e' \
  -font Arial-Bold -pointsize 72 -fill '#6c5ce7' \
  -gravity center -annotate 0 'ROKU OSU-MANIA\n♪ ♫ ♪' \
  images/splash_hd.png

# SD Splash (720x480)
convert -size 720x480 xc:'#1a1a2e' \
  -font Arial-Bold -pointsize 48 -fill '#6c5ce7' \
  -gravity center -annotate 0 'ROKU OSU-MANIA\n♪ ♫ ♪' \
  images/splash_sd.png
```

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

## 📝 License

This project is for educational purposes. Do not include copyrighted songs.

---

## 🙏 Credits

- Inspired by [Web-Osu-Mania](https://github.com/HecticKiwi/Web-Osu-Mania)
- Built for Roku with BrightScript & SceneGraph
- Beatmap generation powered by [librosa](https://librosa.org/)
