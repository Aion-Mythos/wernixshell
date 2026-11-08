#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
"""Renders the line-draw animation of the official logo (assets/logo.svg) to GIFs. Re-runnable.

Writes assets/vxs-anim.gif (for dark themes) and vxs-anim-light.gif: 3.00 s at 25 fps (75 frames of 4 cs),
looping forever, 1-bit transparency, disposal 2, no blur or glow, drawn at 4x and downscaled with Lanczos,
and a small shared palette without dithering. Needs only Pillow.

V, X and S draw on one after another (the V's dot and the X's ring come with them), hold with one pulse of
the accent colour, then erase in the same order. Reads the logo's own shapes from the SVG: polyline, line,
circle (a filled circle is a dot, a stroked one is a ring) and path elements inside translated groups."""
import math
import re
import xml.etree.ElementTree as ET
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
FPS, DURATION = 25, 3.0
FRAMES = int(FPS * DURATION)
SUPERSAMPLE = 4
WIDTH = 512  # Output width in px; the height follows the logo's proportions
PULSE_STEPS = 12  # Distinct pulse colours, keeps the palette small
# (draw start, draw end) per letter, then the erase windows, in seconds
DRAW = {"v": (0.00, 0.60), "x": (0.45, 1.05), "s": (0.90, 1.50)}
ERASE = {"v": (2.40, 2.70), "x": (2.55, 2.85), "s": (2.70, 3.00)}
PULSE = (1.50, 2.40)
# letters, accent, accent at the pulse's peak
VARIANTS = {"": ("fafaff", "956bff", "b14dff"), "-light": ("1c1c1c", "5936d6", "647cff")}
SVG = "{http://www.w3.org/2000/svg}"
def ease(t):
    t = min(1.0, max(0.0, t))
    return t * t * (3 - 2 * t)



def arc_points(p0, rx, ry, phi_deg, large, sweep, p1, steps=32):
    """Points along an SVG elliptical arc (endpoint parameterisation to centre parameterisation)."""
    if (p0 == p1) or rx == 0 or ry == 0:
        return [p1]
    phi = math.radians(phi_deg)
    cp, sp = math.cos(phi), math.sin(phi)
    dx, dy = (p0[0] - p1[0]) / 2, (p0[1] - p1[1]) / 2
    x1, y1 = cp * dx + sp * dy, -sp * dx + cp * dy
    rx, ry = abs(rx), abs(ry)
    lam = x1 * x1 / (rx * rx) + y1 * y1 / (ry * ry)
    if lam > 1:
        rx, ry = rx * math.sqrt(lam), ry * math.sqrt(lam)
    num = rx * rx * ry * ry - rx * rx * y1 * y1 - ry * ry * x1 * x1
    den = rx * rx * y1 * y1 + ry * ry * x1 * x1
    coef = math.sqrt(max(0, num / den)) * (-1 if large == sweep else 1)
    cxp, cyp = coef * rx * y1 / ry, -coef * ry * x1 / rx
    cx, cy = cp * cxp - sp * cyp + (p0[0] + p1[0]) / 2, sp * cxp + cp * cyp + (p0[1] + p1[1]) / 2
    ang = lambda ux, uy, vx, vy: math.atan2(ux * vy - uy * vx, ux * vx + uy * vy)
    t1 = ang(1, 0, (x1 - cxp) / rx, (y1 - cyp) / ry)
    dt = ang((x1 - cxp) / rx, (y1 - cyp) / ry, (-x1 - cxp) / rx, (-y1 - cyp) / ry)
    if not sweep and dt > 0:
        dt -= 2 * math.pi
    elif sweep and dt < 0:
        dt += 2 * math.pi
    out = []
    for k in range(1, steps + 1):
        t = t1 + dt * k / steps
        out.append((cx + rx * math.cos(t) * cp - ry * math.sin(t) * sp, cy + rx * math.cos(t) * sp + ry * math.sin(t) * cp))
    return out


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
        elif c == "A":
            rx, ry, rot, large, sweep, x, y = take(7)
            end = (x + ox, y + oy)
            cur += arc_points(pos, rx, ry, rot, int(large), int(sweep), end)
            pos, last_ctrl = end, None
        elif c == "Z":
            cur.append(start)
            pos = start
            last_ctrl = None
        else:
            raise SystemExit(f"Unsupported path command {cmd!r}")
    if cur:
        lines.append(cur)
    return lines



def mix(a, b, t):
    return tuple(round(x + (y - x) * t) for x, y in zip(a, b))


def rgb(h):
    return tuple(int(h[i : i + 2], 16) for i in (0, 2, 4))




def num(value):
    return [float(v) for v in re.findall(r"-?\d*\.?\d+", value)]


def circle_points(cx, cy, r, steps=96):
    # Starts at the top and runs clockwise
    return [(cx + r * math.sin(2 * math.pi * k / steps), cy - r * math.cos(2 * math.pi * k / steps)) for k in range(steps + 1)]


def clip_outside(p0, p1, rings):
    """The parts of a segment that lie outside every ring (circles of the same glyph)."""
    parts = [(p0, p1)]
    for cx, cy, r in rings:
        nxt = []
        for a, b in parts:
            dx, dy = b[0] - a[0], b[1] - a[1]
            fx, fy = a[0] - cx, a[1] - cy
            qa, qb, qc = dx * dx + dy * dy, 2 * (fx * dx + fy * dy), fx * fx + fy * fy - r * r
            disc = qb * qb - 4 * qa * qc
            if disc <= 0 or qa == 0:
                nxt.append((a, b))
                continue
            t1, t2 = (-qb - math.sqrt(disc)) / (2 * qa), (-qb + math.sqrt(disc)) / (2 * qa)
            at = lambda t: (a[0] + dx * t, a[1] + dy * t)
            if t1 > 0:
                nxt.append((a, at(min(t1, 1))))
            if t2 < 1:
                nxt.append((at(max(t2, 0)), b))
        parts = nxt
    return parts


def parse_logo(path):
    """{glyph: {"strokes": [(kind, polyline)], "dots": [(x, y, r)]}} and the viewBox, from the logo SVG."""
    root = ET.parse(path).getroot()
    view = num(root.get("viewBox"))
    width = float(root.find(SVG + "g").get("stroke-width"))
    glyphs = {}
    for name, group in zip(DRAW, root.findall(SVG + "g")):
        tx, ty = (num(group.get("transform", "")) + [0, 0])[:2]
        shift = lambda p: (p[0] + tx, p[1] + ty)
        lines, rings, dots, ring_strokes = [], [], [], []
        for el in group:
            tag = el.tag.replace(SVG, "")
            if tag == "polyline":
                v = num(el.get("points"))
                lines.append([shift(p) for p in zip(v[0::2], v[1::2])])
            elif tag == "line":
                x1, y1, x2, y2 = (float(el.get(k)) for k in ("x1", "y1", "x2", "y2"))
                lines.append([shift((x1, y1)), shift((x2, y2))])
            elif tag == "path":
                lines += [[shift(p) for p in line] for line in sample_path(el.get("d"))]
            elif tag == "circle":
                cx, cy = shift((float(el.get("cx")), float(el.get("cy"))))
                r = float(el.get("r"))
                if el.get("stroke") == "none":
                    dots.append((cx, cy, r))
                else:
                    rings.append((cx, cy, r))
        strokes = []
        for line in lines:
            if len(line) == 2 and rings:  # Lines stop at the ring instead of crossing it
                strokes += [("letter", [a, b]) for a, b in clip_outside(line[0], line[1], rings)]
            else:
                strokes.append(("letter", line))
        strokes += [("accent", circle_points(*ring)) for ring in rings]
        glyphs[name] = {"strokes": strokes, "dots": dots}
    return glyphs, view, width


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
        pop = ease((f - 0.5) / 0.25)  # Dots grow in as their letter is half drawn
        if pop > 0:
            for cx, cy, r in glyph["dots"]:
                x, y = to_px((cx, cy))
                draws["accent"].ellipse((x - r * ss * pop, y - r * ss * pop, x + r * ss * pop, y + r * ss * pop), fill=255)
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
        out = ROOT / f"assets/vxs-anim{suffix}.gif"
        write_gif(out, images[0].size, palette, frames)
        verify(out, palette, images)
        print(f"{out.relative_to(ROOT)}: {len(frames)} frames, {images[0].size[0]}x{images[0].size[1]}, {len(palette) + 1} colours, {out.stat().st_size / 1024:.0f} KB")


if __name__ == "__main__":
    main()
