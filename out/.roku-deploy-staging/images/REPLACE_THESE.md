# 🖼️ Image Placeholders - REPLACE THESE!

Current images are **1x1 pixel placeholders**. Replace with proper graphics.

## Required Images

| File | Size | Description |
|------|------|-------------|
| `icon_focus_hd.png` | 336 × 210 | HD icon when selected |
| `icon_focus_sd.png` | 246 × 140 | SD icon when selected |
| `icon_side_hd.png` | 108 × 69 | HD icon (unfocused) |
| `icon_side_sd.png` | 108 × 69 | SD icon (unfocused) |
| `splash_hd.png` | 1280 × 720 | HD loading screen |
| `splash_sd.png` | 720 × 480 | SD loading screen |

## Quick Create with ImageMagick

```bash
brew install imagemagick

# Run from project root:
convert -size 336x210 xc:'#6c5ce7' -font Arial-Bold -pointsize 28 -fill white -gravity center -annotate 0 'ROKU\nOSU-MANIA' images/icon_focus_hd.png

convert -size 246x140 xc:'#6c5ce7' -font Arial-Bold -pointsize 20 -fill white -gravity center -annotate 0 'ROKU\nOSU-MANIA' images/icon_focus_sd.png

convert -size 108x69 xc:'#6c5ce7' -font Arial-Bold -pointsize 12 -fill white -gravity center -annotate 0 'OSU' images/icon_side_hd.png

convert -size 108x69 xc:'#6c5ce7' -font Arial-Bold -pointsize 12 -fill white -gravity center -annotate 0 'OSU' images/icon_side_sd.png

convert -size 1280x720 xc:'#1a1a2e' -font Arial-Bold -pointsize 72 -fill '#6c5ce7' -gravity center -annotate 0 'ROKU OSU-MANIA' images/splash_hd.png

convert -size 720x480 xc:'#1a1a2e' -font Arial-Bold -pointsize 48 -fill '#6c5ce7' -gravity center -annotate 0 'ROKU OSU-MANIA' images/splash_sd.png
```

## Design Tips
- **Purple**: #6c5ce7
- **Dark BG**: #1a1a2e
- Include musical notes: ♪ ♫ ♩
- Game title: "ROKU OSU-MANIA"

**Delete this file after replacing images!**
