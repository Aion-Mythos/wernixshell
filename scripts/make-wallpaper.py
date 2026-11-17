#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
"""Renders the WernixOS wallpapers. Re-runnable; the output is committed. Needs Pillow and ffmpeg.

Writes assets/wallpaper.webp (still, 3840x2160) and assets/wallpaper-live.mp4 (1920x1080, 24 fps, a seamless
20 s loop). The picture is the logo continued outward: hexagon rings that each grow by the logo's ratio and
twist by its angle, on the Ebony ground with a Verdigris core. In the loop every ring turns 60 degrees (a
hexagon's symmetry, so the last frame meets the first), neighbours in opposite directions, and the core breathes."""
import math
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
FPS, SECONDS = 24, 20
GROUND, GLOW, RING, CORE, CORE_PEAK = "070504", "0a3637", "44403c", "337774", "63a19c"  # Wernix OS Colour System
RATIO, TWIST = 1.43, 10  # From assets/logo.svg: each ring is 1.43x the one inside it and turned 10 degrees
RINGS = 9


def rgb(h):
    return tuple(int(h[i : i + 2], 16) for i in (0, 2, 4))


def mix(a, b, t):
    return tuple(round(x + (y - x) * t) for x, y in zip(a, b))


def hexagon(cx, cy, r, deg):
    return [(cx + r * math.sin(math.radians(deg + 60 * k)), cy - r * math.cos(math.radians(deg + 60 * k))) for k in range(6)]


def ground(w, h):
    """The Ebony ground with a soft Verdigris glow behind the core."""
    glow = Image.radial_gradient("L").point(lambda v: round(((255 - v) / 255) ** 2.2 * 150))
    side = round(h * 1.5)
    mask = Image.new("L", (w, h), 0)
    mask.paste(glow.resize((side, side), Image.LANCZOS), ((w - side) // 2, (h - side) // 2))
    return Image.composite(Image.new("RGB", (w, h), rgb(GLOW)), Image.new("RGB", (w, h), rgb(GROUND)), mask)


def frame(base, t, ss=2):
    """The picture at loop position t (0..1), drawn at ss times the size of base and scaled down."""
    w, h = base.size[0] * ss, base.size[1] * ss
    img = base.resize((w, h), Image.BILINEAR)
    draw = ImageDraw.Draw(img)
    cx, cy, unit = w / 2, h / 2, h * 0.045  # unit: the radius of the core
    for k in range(RINGS, 0, -1):
        r = unit * 1.83 * RATIO ** (k - 1)
        turn = 60 * t * (1 if k % 2 else -1)
        colour = mix(rgb(RING), rgb(GROUND), min(1, (k - 1) / RINGS) ** 0.7)  # Rings fade into the ground
        pts = hexagon(cx, cy, r, 30 + TWIST * k + turn)
        draw.line(pts + pts[:2], fill=colour, width=max(2, round(r * 0.1)), joint="curve")
    breath = (1 - math.cos(2 * math.pi * t)) / 2
    draw.polygon(hexagon(cx, cy, unit * (1 + 0.04 * breath), 30), fill=mix(rgb(CORE), rgb(CORE_PEAK), breath))
    return img.resize(base.size, Image.LANCZOS)


def main():
    still = frame(ground(3840, 2160), 0)
    still.save(ROOT / "assets/wallpaper.webp", quality=92, method=6)
    base, out = ground(1920, 1080), ROOT / "assets/wallpaper-live.mp4"
    enc = subprocess.Popen(
        ["ffmpeg", "-y", "-loglevel", "error", "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", "1920x1080", "-r", str(FPS), "-i", "-"]
        + ["-c:v", "libx264", "-preset", "slow", "-crf", "20", "-pix_fmt", "yuv420p", "-movflags", "+faststart", str(out)],
        stdin=subprocess.PIPE,
    )
    n = FPS * SECONDS
    first = frame(base, 0)
    assert not ImageChops.difference(first, frame(base, 1)).getbbox(), "the loop does not close"
    for i in range(n):
        enc.stdin.write((first if i == 0 else frame(base, i / n)).tobytes())
    enc.stdin.close()
    if enc.wait():
        sys.exit("ffmpeg failed")
    for p in (ROOT / "assets/wallpaper.webp", out):
        print(f"{p.relative_to(ROOT)}: {p.stat().st_size / 1024:.0f} KB")


if __name__ == "__main__":
    main()
