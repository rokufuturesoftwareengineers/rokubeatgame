#!/bin/bash
# Serve the rhythm-remote-pad companion app over HTTP on your local network
# Usage: ./tools/serve-companion.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DIST_DIR="$SCRIPT_DIR/rhythm-remote-pad/dist"
PORT=8081

# Build if dist doesn't exist
if [ ! -d "$DIST_DIR" ]; then
    echo "📦 Building companion app..."
    cd "$SCRIPT_DIR/rhythm-remote-pad" && npm run build
fi

# Get local IP
LOCAL_IP=$(ipconfig getifaddr en0 2>/dev/null || hostname -I 2>/dev/null | awk '{print $1}')

echo ""
echo "🎮 Rhythm Remote Pad - Local Server"
echo "===================================="
echo "📱 Open on your phone: http://${LOCAL_IP}:${PORT}"
echo "🔗 Or scan the QR code on the Song Select screen"
echo ""
echo "Press Ctrl+C to stop"
echo ""

# Serve using Python's built-in HTTP server
cd "$DIST_DIR" && python3 -m http.server "$PORT" --bind 0.0.0.0
