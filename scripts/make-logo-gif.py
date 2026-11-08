#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
"""Renders the line-draw animation of assets/logo.svg (paths with ids v, x, s) to GIFs. Re-runnable.

Writes assets/vxs-anim-512.gif, vxs-anim-128.gif and the -light variants: 3.00 s at 25 fps (75 frames of
4 cs), looping forever, 1-bit transparency, disposal 2, no blur/glow, 4x supersampling with Lanczos, and a
small shared palette without dithering. Needs only Pillow; supports the path commands M L H V C S Q T Z."""
import math
import re
import xml.etree.ElementTree as ET
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
FPS, DURATION = 25, 3.0
FRAMES = int(FPS * DURATION)
SUPERSAMPLE = 4
MARGIN = 0.12
PULSE_STEPS = 12  # Distinct pulse colours, keeps the palette small
# (draw start, draw end) per glyph, then the erase windows, in seconds
DRAW = {"v": (0.00, 0.60), "x": (0.45, 1.05), "s": (0.90, 1.50)}
ERASE = {"v": (2.40, 2.70), "x": (2.55, 2.85), "s": (2.70, 3.00)}
PULSE = (1.50, 2.40)
VARIANTS = {"": ("956bff", "b14dff"), "-light": ("5936d6", "647cff")}
SIZES = {512: 6.0, 128: 1.5}  # Output px: stroke width at that size


def ease(t):
    t = min(1.0, max(0.0, t))
    return t * t * (3 - 2 * t)


def sample_path(d, steps=48):
    """Polylines (lists of points in viewBox units) for the path data."""
    tokens = re.findall(r"[MmLlHhVvCcSsQqTtZzAa]|-?\d*\.?\d+(?:e-?\d+)?", d)
    lines, cur, start, pos, last_ctrl, cmd, i = [], [], (0, 0), (0, 0), None, "", 0

    def take(n):
        nonlocal i
        vals = [float(t) for t in tokens[i : i + n]]
        i += n
        return vals

    def bezier(p0, pts):
        n = len(pts)
        out = []
        for k in range(1, steps + 1):
            t = k / steps
            pts_all = [p0, *pts]
            while len(pts_all) > 1:
                pts_all = [((1 - t) * a[0] + t * b[0], (1 - t) * a[1] + t * b[1]) for a, b in zip(pts_all, pts_all[1:])]
            out.append(pts_all[0])
        return out

    while i < len(tokens):
        if re.fullmatch(r"[A-Za-z]", tokens[i]):
            cmd = tokens[i]
            i += 1
        rel = cmd.islower()
        c = cmd.upper()
        ox, oy = pos if rel else (0, 0)
        if c == "M":
            x, y = take(2)
            pos = start = (x + ox, y + oy)
            if cur:
                lines.append(cur)
            cur = [pos]
            cmd = "l" if rel else "L"
            last_ctrl = None
        elif c == "L":
            x, y = take(2)
            pos = (x + ox, y + oy)
            cur.append(pos)
            last_ctrl = None
        elif c == "H":
            (x,) = take(1)
            pos = (x + ox, pos[1])
            cur.append(pos)
            last_ctrl = None
        elif c == "V":
            (y,) = take(1)
            pos = (pos[0], y + oy)
            cur.append(pos)
            last_ctrl = None
        elif c in "CS":
            if c == "C":
                x1, y1, x2, y2, x, y = take(6)
                p1 = (x1 + ox, y1 + oy)
            else:
                x2, y2, x, y = take(4)
                p1 = (2 * pos[0] - last_ctrl[0], 2 * pos[1] - last_ctrl[1]) if last_ctrl else pos
            p2, p3 = (x2 + ox, y2 + oy), (x + ox, y + oy)
            cur += bezier(pos, [p1, p2, p3])
            pos, last_ctrl = p3, p2
        elif c in "QT":
            if c == "Q":
                x1, y1, x, y = take(4)
                p1 = (x1 + ox, y1 + oy)
            else:
                x, y = take(2)
                p1 = (2 * pos[0] - last_ctrl[0], 2 * pos[1] - last_ctrl[1]) if last_ctrl else pos
            p2 = (x + ox, y + oy)
            cur += bezier(pos, [p1, p2])
            pos, last_ctrl = p2, p1
        elif c == "Z":
            cur.append(start)
            pos = start
            last_ctrl = None
        else:
            raise SystemExit(f"Unsupported path command {cmd!r}; convert arcs to curves (e.g. in Inkscape)")
    if cur:
        lines.append(cur)
    return lines


def prefix(lines, fraction):
    """The first `fraction` of the total length of the polylines, as polylines."""
    total = sum(math.dist(a, b) for line in lines for a, b in zip(line, line[1:]))
    left, out = total * fraction, []
    for line in lines:
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
        out.append(piece)
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


def mix(a, b, t):
    return tuple(round(x + (y - x) * t) for x, y in zip(a, b))


def rgb(h):
    return tuple(int(h[i : i + 2], 16) for i in (0, 2, 4))


def fit(glyphs, view):
    """Scale and centre all glyphs into the canvas minus the margin (stroke included)."""
    pts = [p for lines in glyphs.values() for line in lines for p in line]
    xs, ys = [p[0] for p in pts], [p[1] for p in pts]
    return min(xs), max(xs), min(ys), max(ys)


def render_frame(glyphs, t, size, stroke):
    ss = size * SUPERSAMPLE
    mask = Image.new("L", (ss, ss), 0)
    draw = ImageDraw.Draw(mask)
    x0, x1, y0, y1 = BOUNDS
    # Fit the logo (plus half a stroke) inside the margins, keeping its proportions and centring it
    inner = size * (1 - 2 * MARGIN) - stroke
    scale = inner / max(x1 - x0, y1 - y0) * SUPERSAMPLE
    cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
    to_px = lambda p: ((p[0] - cx) * scale + ss / 2, (p[1] - cy) * scale + ss / 2)
    w = stroke * SUPERSAMPLE
    r = w / 2
    for name, lines in glyphs.items():
        f = fraction_at(name, t)
        if f <= 1e-4:
            continue
        for line in prefix(lines, f):
            px = [to_px(p) for p in line]
            if len(px) > 1:
                draw.line(px, fill=255, width=round(w), joint="curve")
            for x, y in (px[0], px[-1]):  # Round caps
                draw.ellipse((x - r, y - r, x + r, y + r), fill=255)
    small = mask.resize((size, size), Image.LANCZOS)
    return small.point(lambda v: 255 if v >= 128 else 0)


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
    out = bytearray(b"GIF89a" + size.to_bytes(2, "little") * 2 + bytes([0x80 | (7 << 4) | (bits - 1), 0, 0]))
    out += bytes(c for col in table for c in col)
    out += b"\x21\xff\x0bNETSCAPE2.0\x03\x01\x00\x00\x00"  # Loop forever
    for box, pixels in frames:
        out += b"\x21\xf9\x04" + bytes([(2 << 2) | 1]) + (100 // FPS).to_bytes(2, "little") + b"\x00\x00"
        x0, y0, x1, y1 = box
        out += b"\x2c" + x0.to_bytes(2, "little") + y0.to_bytes(2, "little") + (x1 - x0).to_bytes(2, "little") + (y1 - y0).to_bytes(2, "little") + b"\x00"
        out += bytes([min_size]) + blocks(lzw(pixels, min_size))
    path.write_bytes(bytes(out) + b"\x3b")


def verify(path, size, masks, colours):
    """Reads the GIF back with Pillow: frame count, delays, loop, disposal, transparency and pixels."""
    with Image.open(path) as im:
        assert im.n_frames == FRAMES, f"{path.name}: {im.n_frames} frames"
        assert im.info.get("loop") == 0
        for i in range(FRAMES):
            im.seek(i)
            assert im.info["duration"] == 1000 // FPS and im.disposal_method == 2 and im.size == (size, size)
            rgba = im.convert("RGBA")
            alpha = rgba.getchannel("A")
            assert set(alpha.tobytes()) <= {0, 255}, "partial transparency"
            assert alpha.tobytes() == masks[i].tobytes(), f"frame {i} differs"
            if masks[i].getbbox():
                x, y = next((x, y) for y in range(size) for x in range(size) if masks[i].getpixel((x, y)))
                assert rgba.getpixel((x, y))[:3] == colours[i], f"frame {i} colour"


def pulse_colour(t, base, peak):
    if not PULSE[0] <= t < PULSE[1]:
        return base
    k = (1 - math.cos(2 * math.pi * (t - PULSE[0]) / (PULSE[1] - PULSE[0]))) / 2
    return mix(base, peak, round(k * PULSE_STEPS) / PULSE_STEPS)


def main():
    global BOUNDS
    tree = ET.parse(ROOT / "assets/logo.svg")
    glyphs = {}
    for el in tree.iter("{http://www.w3.org/2000/svg}path"):
        if el.get("id") in DRAW:
            glyphs[el.get("id")] = sample_path(el.get("d"))
    missing = set(DRAW) - set(glyphs)
    if missing:
        raise SystemExit(f"assets/logo.svg has no path with id {sorted(missing)}")
    BOUNDS = fit(glyphs, None)

    for suffix, (base, peak) in VARIANTS.items():
        base, peak = rgb(base), rgb(peak)
        for size, stroke in SIZES.items():
            masks = [render_frame(glyphs, i / FPS, size, stroke) for i in range(FRAMES)]
            colours = [pulse_colour(i / FPS, base, peak) for i in range(FRAMES)]
            palette = sorted(set(colours))
            assert len(palette) < 32, "palette too large"
            frames = []
            for mask, col in zip(masks, colours):
                box = mask.getbbox() or (0, 0, 1, 1)  # Empty frame: one transparent pixel
                crop = mask.crop(box)
                idx = palette.index(col) + 1
                frames.append((box, bytes(idx if v else 0 for v in crop.tobytes())))
            out = ROOT / f"assets/vxs-anim-{size}{suffix}.gif"
            write_gif(out, size, palette, frames)
            verify(out, size, masks, colours)
            print(f"{out.relative_to(ROOT)}: {len(frames)} frames, {len(palette) + 1} colours, {out.stat().st_size / 1024:.0f} KB")


if __name__ == "__main__":
    main()
