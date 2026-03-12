#!/usr/bin/env python3
"""Generate QR code PNG for the companion app URL using current LAN IP."""

import subprocess
import sys

try:
    import qrcode
except ImportError:
    subprocess.check_call([sys.executable, "-m", "pip", "install", "qrcode[pil]"])
    import qrcode

ip = subprocess.check_output(["ipconfig", "getifaddr", "en0"]).decode().strip()
url = f"http://{ip}:8081/"
img = qrcode.make(url, box_size=8, border=2)

import os
out_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "images", "qr_remote.png")
img.save(out_path)
print(f"QR code saved: {url} -> {out_path}")
