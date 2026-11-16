#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
"""Renders the line-draw animation of the official logo (assets/logo.svg) to GIFs. Re-runnable.

Writes assets/wernix-anim.gif (for dark themes) and wernix-anim-light.gif: 3.00 s at 25 fps (75 frames of 4 cs),
looping forever, 1-bit transparency, disposal 2, no blur or glow, drawn at 4x and downscaled with Lanczos,
and a small shared palette without dithering. Needs only Pillow.

The three rings draw on from the outside in (the core grows in with the last one), hold with one pulse of
the accent colour, then erase in the same order. Reads the logo's own polygons from the SVG: a stroked
polygon is a ring, the filled one is the core."""
import math
import re
import xml.etree.ElementTree as ET
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
FPS, DURATION = 25, 3.0
FRAMES = int(FPS * DURATION)
SUPERSAMPLE = 4
WIDTH = 320  # Output width in px; the height follows the logo's proportions
PULSE_STEPS = 12  # Distinct pulse colours, keeps the palette small
# (draw start, draw end) per ring, then the erase windows, in seconds
DRAW = {"outer": (0.00, 0.60), "middle": (0.45, 1.05), "inner": (0.90, 1.50)}
ERASE = {"outer": (2.40, 2.70), "middle": (2.55, 2.85), "inner": (2.70, 3.00)}
PULSE = (1.50, 2.40)
# rings, core, core at the pulse's peak
VARIANTS = {"": ("f2f0ec", "63a19c", "8dc0bb"), "-light": ("13100d", "337774", "63a19c")}
SVG = "{http://www.w3.org/2000/svg}"
def ease(t):
    t = min(1.0, max(0.0, t))
    return t * t * (3 - 2 * t)



def mix(a, b, t):
    return tuple(round(x + (y - x) * t) for x, y in zip(a, b))


def rgb(h):
    return tuple(int(h[i : i + 2], 16) for i in (0, 2, 4))




def num(value):
    return [float(v) for v in re.findall(r"-?\d*\.?\d+", value)]


def parse_logo(path):
    """{ring: {"strokes": [(kind, polyline)], "dots": [polygon]}} and the viewBox, from the logo SVG."""
    root = ET.parse(path).getroot()
    view = num(root.get("viewBox"))
    polys = [(el, list(zip(*[iter(num(el.get("points")))] * 2))) for el in root.findall(SVG + "polygon")]
    rings = [(el, pts) for el, pts in polys if el.get("fill") == "none"]
    cores = [pts for el, pts in polys if el.get("fill") != "none"]
    assert len(rings) == len(DRAW) and cores, "expected three rings and a core"
    glyphs = {name: {"strokes": [("letter", pts + [pts[0]])], "dots": []} for name, (_, pts) in zip(DRAW, rings)}
    glyphs[list(DRAW)[-1]]["dots"] = cores
    return glyphs, view, float(rings[0][0].get("stroke-width"))


def prefix(strokes, fraction):
    """The first `fraction` of the total length of the strokes, as (kind, polyline) pieces."""
    total = sum(math.dist(a, b) for _, line in strokes for a, b in zip(line, line[1:]))
    left, out = total * fraction, []
    for kind, line in strokes:
        piece = [line[0]]
        for a, b in zip(line, line[1:]):
            seg = math.dist(a, b)
            if seg >= left:
                t = left / seg if seg else 0
                piece.append((a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t))
                left = 0
                break
            piece.append(b)
            left -= seg
        out.append((kind, piece))
        if left <= 0:
            break
    return out


def fraction_at(glyph, t):
    """How much of a glyph is drawn at time t."""
    if t < DRAW[glyph][1]:
        return ease((t - DRAW[glyph][0]) / (DRAW[glyph][1] - DRAW[glyph][0]))
    if t < ERASE[glyph][0]:
        return 1.0
    return 1 - ease((t - ERASE[glyph][0]) / (ERASE[glyph][1] - ERASE[glyph][0]))


def render_masks(glyphs, view, stroke_width, t):
    """(letter mask, accent mask) of the logo at time t, 1-bit, at the output size."""
    w = WIDTH
    h = round(WIDTH * view[3] / view[2])
    ss = SUPERSAMPLE * w / view[2]  # px per viewBox unit at the supersampled size
    masks = {k: Image.new("L", (w * SUPERSAMPLE, h * SUPERSAMPLE), 0) for k in ("letter", "accent")}
    draws = {k: ImageDraw.Draw(m) for k, m in masks.items()}
    to_px = lambda p: ((p[0] - view[0]) * ss, (p[1] - view[1]) * ss)
    lw = stroke_width * ss
    for name, glyph in glyphs.items():
        f = fraction_at(name, t)
        if f <= 1e-4:
            continue
        for kind, line in prefix(glyph["strokes"], f):
            px = [to_px(p) for p in line]
            d = draws[kind]
            if len(px) > 1:
                d.line(px, fill=255, width=round(lw), joint="curve")
            for x, y in (px[0], px[-1]):  # Round caps
                d.ellipse((x - lw / 2, y - lw / 2, x + lw / 2, y + lw / 2), fill=255)
        pop = ease((f - 0.5) / 0.25)  # The core grows in as its ring is half drawn
        if pop > 0:
            for poly in glyph["dots"]:  # Scaled about the centre of the logo
                draws["accent"].polygon([to_px((x * pop, y * pop)) for x, y in poly], fill=255)
    return [m.resize((w, h), Image.LANCZOS).point(lambda v: 255 if v >= 128 else 0) for m in (masks["letter"], masks["accent"])]


def accent_colour(t, base, peak):
    if not PULSE[0] <= t < PULSE[1]:
        return base
    k = (1 - math.cos(2 * math.pi * (t - PULSE[0]) / (PULSE[1] - PULSE[0]))) / 2
    return mix(base, peak, round(k * PULSE_STEPS) / PULSE_STEPS)
def lzw(pixels, min_size):
    """GIF LZW of a sequence of palette indices."""
    clear, end = 1 << min_size, (1 << min_size) + 1
    out, acc, nbits = bytearray(), 0, 0

    def emit(code, size):
        nonlocal acc, nbits
        acc |= code << nbits
        nbits += size
        while nbits >= 8:
            out.append(acc & 255)
            acc >>= 8
            nbits -= 8

    size, nxt, table, prefix = min_size + 1, end + 1, {}, None
    emit(clear, size)
    for px in pixels:
        if prefix is None:
            prefix = px
            continue
        key = (prefix << 8) | px
        if key in table:
            prefix = table[key]
            continue
        emit(prefix, size)
        if nxt < 4096:
            table[key] = nxt
            nxt += 1
            if nxt > (1 << size) and size < 12:
                size += 1
        else:
            emit(clear, size)
            table, nxt, size = {}, end + 1, min_size + 1
        prefix = px
    emit(prefix, size)
    emit(end, size)
    if nbits:
        out.append(acc & 255)
    return bytes(out)



def blocks(data):
    out = bytearray()
    for i in range(0, len(data), 255):
        chunk = data[i : i + 255]
        out += bytes([len(chunk)]) + chunk
    return bytes(out) + b"\x00"



def write_gif(path, size, palette, frames):
    """GIF89a: global palette (index 0 transparent), every frame cropped to its content, disposal 2, looping.
    Pillow is not used to save because it merges identical frames, which would drop frames."""
    bits = max(1, math.ceil(math.log2(len(palette) + 1)))
    table = [(0, 0, 0)] + palette
    table += [(0, 0, 0)] * ((1 << bits) - len(table))
    min_size = max(2, bits)
    out = bytearray(b"GIF89a" + size[0].to_bytes(2, "little") + size[1].to_bytes(2, "little") + bytes([0x80 | (7 << 4) | (bits - 1), 0, 0]))
    out += bytes(c for col in table for c in col)
    out += b"\x21\xff\x0bNETSCAPE2.0\x03\x01\x00\x00\x00"  # Loop forever
    for box, pixels in frames:
        out += b"\x21\xf9\x04" + bytes([(2 << 2) | 1]) + (100 // FPS).to_bytes(2, "little") + b"\x00\x00"
        x0, y0, x1, y1 = box
        out += b"\x2c" + x0.to_bytes(2, "little") + y0.to_bytes(2, "little") + (x1 - x0).to_bytes(2, "little") + (y1 - y0).to_bytes(2, "little") + b"\x00"
        out += bytes([min_size]) + blocks(lzw(pixels, min_size))
    path.write_bytes(bytes(out) + b"\x3b")



def verify(path, palette, images):
    """Reads the GIF back with Pillow: frame count, delays, loop, disposal, transparency and pixels."""
    with Image.open(path) as im:
        assert im.n_frames == FRAMES, f"{path.name}: {im.n_frames} frames"
        assert im.info.get("loop") == 0
        for i, expected in enumerate(images):
            im.seek(i)
            assert im.info["duration"] == 1000 // FPS and im.disposal_method == 2 and im.size == expected.size
            rgba = im.convert("RGBA")
            assert set(rgba.getchannel("A").tobytes()) <= {0, 255}, "partial transparency"
            exp = expected.copy()
            exp.putpalette([0, 0, 0] + [c for col in palette for c in col])
            exp.info["transparency"] = 0
            assert rgba.tobytes() == exp.convert("RGBA").tobytes(), f"frame {i} differs"


def main():
    glyphs, view, stroke_width = parse_logo(ROOT / "assets/logo.svg")
    for suffix, (letters, accent, peak) in VARIANTS.items():
        letters, accent, peak = rgb(letters), rgb(accent), rgb(peak)
        accents = [accent_colour(i / FPS, accent, peak) for i in range(FRAMES)]
        palette = [letters] + sorted(set(accents))  # Index 0 is transparent, 1 the letters, then the accents
        assert len(palette) < 32, "palette too large"
        images, frames = [], []
        for i in range(FRAMES):
            letter_mask, accent_mask = render_masks(glyphs, view, stroke_width, i / FPS)
            img = Image.new("L", letter_mask.size, 0)
            img.paste(1, mask=letter_mask)
            img.paste(palette.index(accents[i]) + 1, mask=accent_mask)
            images.append(img)
            box = img.getbbox() or (0, 0, 1, 1)  # Empty frame: one transparent pixel
            frames.append((box, img.crop(box).tobytes()))
        out = ROOT / f"assets/wernix-anim{suffix}.gif"
        write_gif(out, images[0].size, palette, frames)
        verify(out, palette, images)
        print(f"{out.relative_to(ROOT)}: {len(frames)} frames, {images[0].size[0]}x{images[0].size[1]}, {len(palette) + 1} colours, {out.stat().st_size / 1024:.0f} KB")


if __name__ == "__main__":
    main()
