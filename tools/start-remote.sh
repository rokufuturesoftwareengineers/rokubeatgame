#!/bin/bash
# ──────────────────────────────────────────────────────────────
#  🎮 Start Rhythm Remote Pad — One Command, Everything Runs
# ──────────────────────────────────────────────────────────────
#  Usage:  ./tools/start-remote.sh
#  Starts: 1) Auto-regenerates QR code for current network
#          2) WebSocket relay server (port 3002)
#          3) Companion web app (port 8081)
#  Stop:   Press Ctrl+C (kills both)
# ──────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REMOTE_DIR="$SCRIPT_DIR/rhythm-remote-pad"
SERVER_DIR="$REMOTE_DIR/server"
QR_IMAGE="$WORKSPACE_DIR/images/qr_remote.png"
QR_HTML="$REMOTE_DIR/qr-code.html"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Get local IP
LOCAL_IP=$(ipconfig getifaddr en0 2>/dev/null || hostname -I 2>/dev/null | awk '{print $1}')
if [ -z "$LOCAL_IP" ]; then
    LOCAL_IP="localhost"
fi

COMPANION_URL="http://${LOCAL_IP}:8081/"

# ── Auto-regenerate QR code for current network ───────────────
echo -e "${CYAN}📸 Generating QR code for ${COMPANION_URL}...${NC}"
python3 -c "
import sys
try:
    import qrcode
    img = qrcode.make('${COMPANION_URL}', box_size=8, border=2)
    img.save('${QR_IMAGE}')
    print('   ✅ QR code saved to images/qr_remote.png')
except ImportError:
    print('   ⚠️  qrcode module not installed. Run: pip3 install \"qrcode[pil]\"')
    print('   ⚠️  Skipping QR code generation (old QR will be used)')
"

# Also update the qr-code.html with the current IP
cat > "$QR_HTML" << QREOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rhythm Remote Pad QR Code</title>
    <style>
        body {
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            margin: 0;
            font-family: Arial, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }
        .container {
            text-align: center;
            background: white;
            padding: 2rem;
            border-radius: 1rem;
            box-shadow: 0 10px 40px rgba(0,0,0,0.2);
        }
        h1 { color: #333; margin-bottom: 1rem; }
        .url { color: #667eea; font-weight: bold; margin: 1rem 0; font-size: 1.2rem; }
        p { color: #666; margin-bottom: 1.5rem; }
        #qrcode { margin: 2rem auto; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🎮 Rhythm Remote Pad</h1>
        <p>Scan this QR code with your phone to open the controller</p>
        <div id="qrcode"></div>
        <p class="url">${COMPANION_URL}</p>
        <p style="font-size: 0.9rem;">Make sure your phone is on the same WiFi network</p>
    </div>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/qrcodejs/1.0.0/qrcode.min.js"></script>
    <script>
        new QRCode(document.getElementById("qrcode"), {
            text: "${COMPANION_URL}",
            width: 256, height: 256,
            colorDark: "#000000", colorLight: "#ffffff",
            correctLevel: QRCode.CorrectLevel.H
        });
    </script>
</body>
</html>
QREOF
echo -e "   ${GREEN}✅ qr-code.html updated${NC}"

# ── Kill old processes on our ports ────────────────────────────
cleanup() {
    echo ""
    echo -e "${YELLOW}🛑 Shutting down...${NC}"
    kill $RELAY_PID $VITE_PID 2>/dev/null
    wait $RELAY_PID $VITE_PID 2>/dev/null
    echo -e "${GREEN}✅ All servers stopped${NC}"
    exit 0
}
trap cleanup SIGINT SIGTERM

# Kill anything already on our ports
lsof -ti :3002 | xargs kill -9 2>/dev/null
lsof -ti :8081 | xargs kill -9 2>/dev/null

# ── Check dependencies ────────────────────────────────────────
if [ ! -d "$REMOTE_DIR/node_modules" ]; then
    echo -e "${YELLOW}📦 Installing companion app dependencies...${NC}"
    cd "$REMOTE_DIR" && npm install
fi

if [ ! -d "$SERVER_DIR/node_modules" ]; then
    echo -e "${YELLOW}📦 Installing relay server dependencies...${NC}"
    cd "$SERVER_DIR" && npm install
fi

# ── Start relay server ────────────────────────────────────────
echo -e "${CYAN}🔌 Starting relay server...${NC}"
cd "$SERVER_DIR" && node server.js &
RELAY_PID=$!

# Give the relay a moment to start
sleep 1

# ── Start Vite dev server ─────────────────────────────────────
echo -e "${CYAN}📱 Starting companion app...${NC}"
cd "$REMOTE_DIR" && npx vite --host 0.0.0.0 --port 8081 &
VITE_PID=$!

# Give Vite a moment to start
sleep 2

# ── Print summary ─────────────────────────────────────────────
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║       🎮 Rhythm Remote Pad — Ready to Play!            ║${NC}"
echo -e "${GREEN}╠══════════════════════════════════════════════════════════╣${NC}"
echo -e "${GREEN}║                                                        ║${NC}"
echo -e "${GREEN}║  📱 Open on phone: ${CYAN}http://${LOCAL_IP}:8081${GREEN}$(printf '%*s' $((17 - ${#LOCAL_IP})) '')║${NC}"
echo -e "${GREEN}║  🔌 Relay server: ${CYAN}ws://${LOCAL_IP}:3002${GREEN}$(printf '%*s' $((18 - ${#LOCAL_IP})) '')║${NC}"
echo -e "${GREEN}║                                                        ║${NC}"
echo -e "${GREEN}║  1. Open the URL above on your phone                   ║${NC}"
echo -e "${GREEN}║  2. Enter your Roku's IP address                       ║${NC}"
echo -e "${GREEN}║  3. Press the lanes to play!                           ║${NC}"
echo -e "${GREEN}║                                                        ║${NC}"
echo -e "${GREEN}║  Press Ctrl+C to stop all servers                      ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Wait for either process to exit
wait $RELAY_PID $VITE_PID
