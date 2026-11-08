#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
"""Builds data/schemes/<name>/<flavour>.json (the scheme.json format the shell loads) from small seeds in
data/seeds/<name>/<flavour>.json. Re-runnable; the output is committed.

Seed keys: mode, background, surface, primary, secondary, tertiary, error, text (required);
source (where the palette comes from) and flavour (default: the file name) are informational;
strictContrast (optional) pushes text on coloured fills to at least 4.5:1;
success, warning (optional); overrides {token: hex} (optional, replaces any generated token).
To add a theme, add a seed and run this script. Every token the shell reads (the M3Palette in
services/Colours.qml) is generated, and the script fails if one is missing."""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BLACK, WHITE = "000000", "ffffff"


def rgb(h):
    return [int(h[i : i + 2], 16) for i in (0, 2, 4)]


def mix(a, b, t):
    return "".join("%02x" % round(x * (1 - t) + y * t) for x, y in zip(rgb(a), rgb(b)))


def lum(h):
    f = lambda v: v / 12.92 if v <= 0.03928 else ((v + 0.055) / 1.055) ** 2.4
    r, g, b = (f(v / 255) for v in rgb(h))
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def contrast(a, b):
    hi, lo = sorted((lum(a), lum(b)), reverse=True)
    return (hi + 0.05) / (lo + 0.05)


def tokens():
    """Token names the shell reads, from the M3Palette in services/Colours.qml."""
    src = (ROOT / "services/Colours.qml").read_text()
    names = {m.group(1) for m in re.finditer(r"property color m3(\w+)", src)}
    names |= {m.group(1) for m in re.finditer(r"property color (term\d+)", src)}
    return sorted(names)


def build(seed):
    dark = seed["mode"] == "dark"
    b, s, t = seed["background"], seed["surface"], seed["text"]
    ok = seed.get("success", "6fcf97" if dark else "1b7f4c")
    warn = seed.get("warning", "e3b341" if dark else "9a6700")
    pick = lambda bg: max((b, t), key=lambda c: contrast(c, bg))  # Readable text on bg
    if seed.get("strictContrast"):  # Text on coloured fills gets pushed towards white/black until it reaches 4.5:1

        def pick(bg, base=pick):
            fg = base(bg)
            for _ in range(40):
                if contrast(fg, bg) >= 4.6:
                    break
                fg = mix(fg, WHITE if lum(bg) < 0.4 else BLACK, 0.1)
            return fg
    c = {
        "background": b, "onBackground": t, "surface": s, "onSurface": t,
        "surfaceDim": mix(s, BLACK, 0.25) if dark else mix(s, t, 0.12),
        "surfaceBright": mix(s, t, 0.18) if dark else s,
        "surfaceContainerLowest": mix(s, BLACK, 0.15) if dark else WHITE,
        "surfaceContainerLow": mix(s, t, 0.04 if dark else 0.03),
        "surfaceContainer": mix(s, t, 0.08 if dark else 0.06),
        "surfaceContainerHigh": mix(s, t, 0.12 if dark else 0.10),
        "surfaceContainerHighest": mix(s, t, 0.17 if dark else 0.15),
        "surfaceVariant": mix(s, t, 0.12 if dark else 0.10),
        "onSurfaceVariant": mix(t, s, 0.25),
        "outline": mix(t, s, 0.55), "outlineVariant": mix(s, t, 0.25 if dark else 0.2),
        "inverseSurface": t, "inverseOnSurface": s,
        "inversePrimary": mix(seed["primary"], BLACK if dark else WHITE, 0.45),
        "shadow": BLACK, "scrim": BLACK, "surfaceTint": seed["primary"],
        "neutral_paletteKeyColor": mix(t, s, 0.5), "neutral_variant_paletteKeyColor": mix(t, s, 0.6),
    }
    c["neutralPaletteKeyColor"] = c["neutral_paletteKeyColor"]
    c["neutralVariantPaletteKeyColor"] = c["neutral_variant_paletteKeyColor"]
    for role, col in (("primary", seed["primary"]), ("secondary", seed["secondary"]), ("tertiary", seed["tertiary"]), ("error", seed["error"]), ("success", ok)):
        cap = role.capitalize()
        c[role] = col
        c[f"on{cap}"] = pick(col)
        c[f"{role}Container"] = mix(col, b, (0.65 if dark else 0.8) if seed.get("strictContrast") else (0.55 if dark else 0.75))
        c[f"on{cap}Container"] = pick(c[f"{role}Container"])
        c[f"{role}_paletteKeyColor"] = c[f"{role}PaletteKeyColor"] = col
        if role in ("primary", "secondary", "tertiary"):
            c[f"{role}Fixed"] = mix(col, WHITE, 0.7)
            c[f"{role}FixedDim"] = mix(col, WHITE, 0.35)
            c[f"on{cap}Fixed"] = mix(col, BLACK, 0.7)
            c[f"on{cap}FixedVariant"] = mix(col, BLACK, 0.4)
    cyan = mix(seed["secondary"], ok, 0.5)
    ansi = [mix(s, t, 0.12), seed["error"], ok, warn, seed["secondary"], seed["tertiary"], cyan, mix(t, s, 0.15)]
    bright = [mix(s, t, 0.4)] + [mix(x, WHITE if dark else BLACK, 0.25) for x in ansi[1:7]] + [t]
    for i, col in enumerate(ansi + bright):
        c[f"term{i}"] = col
    c.update(seed.get("overrides", {}))
    return c


REPORT = [
    ("onSurface", "surface"), ("onSurface", "surfaceContainerLowest"), ("onSurface", "surfaceContainerHighest"),
    ("onSurfaceVariant", "surface"), ("primary", "background"), ("onPrimary", "primary"),
    ("onPrimaryContainer", "primaryContainer"), ("secondary", "background"), ("tertiary", "background"),
    ("error", "background"), ("success", "background"),
]


def report(name, colours):
    """Prints the contrast ratio of the key text/background pairs."""
    print(name + ": " + ", ".join(f"{a}/{b} {contrast(colours[a], colours[b]):.1f}" for a, b in REPORT))


def main():
    show_report = "--report" in sys.argv
    names = tokens()
    for seed_file in sorted((ROOT / "data/seeds").glob("*/*.json")):
        seed = json.loads(seed_file.read_text())
        colours = build(seed)
        missing = [n for n in names if n not in colours]
        if missing:
            sys.exit(f"{seed_file}: missing tokens {missing}")
        out = ROOT / "data/schemes" / seed_file.parent.name / seed_file.name
        out.parent.mkdir(parents=True, exist_ok=True)
        scheme = {"name": seed_file.parent.name, "flavour": seed.get("flavour", seed_file.stem), "mode": seed["mode"], "colours": {n: colours[n] for n in names}}
        out.write_text(json.dumps(scheme, indent=2) + "\n")
        low = [f"{a}/{b}={contrast(colours[a], colours[b]):.1f}" for a, b in (("onSurface", "surface"), ("onPrimary", "primary"), ("onSecondary", "secondary"), ("onTertiary", "tertiary"), ("onError", "error")) if contrast(colours[a], colours[b]) < 4.5]
        if show_report:
            report(f"{seed_file.parent.name}/{seed_file.stem}", colours)
        print(f"{out.relative_to(ROOT)}: {len(names)} tokens" + (f" (low contrast: {', '.join(low)})" if low else ""))


if __name__ == "__main__":
    main()
