#!/usr/bin/env python3
"""Adds blank space ABOVE a phone screenshot so nothing is hidden behind the iPhone's clock/Dynamic Island and the Claude app's Close / Edit / Share buttons
when Shane opens the picture full screen (Shane, 2026-11-18: "make sure you got enough space on top").
USE ON EVERY IMAGE SENT TO SHANE. Rule of thumb: the top 330 px of a 1170 px-wide picture (110 CSS px at 3x) is covered; pad at least that much.
  python3 docs/key-integration/pad_screenshot.py in.png out.png [top_px=330] [bottom_px=60] [#0f171e]"""
import sys
from PIL import Image
src, dst = sys.argv[1], sys.argv[2]
top = int(sys.argv[3]) if len(sys.argv) > 3 else 330
bot = int(sys.argv[4]) if len(sys.argv) > 4 else 60
col = sys.argv[5] if len(sys.argv) > 5 else '#0f171e'
im = Image.open(src).convert('RGB')
scale = im.width / 1170.0
top = int(round(top * scale)); bot = int(round(bot * scale))
out = Image.new('RGB', (im.width, im.height + top + bot), col)
out.paste(im, (0, top))
out.save(dst)
print(dst, out.size)
