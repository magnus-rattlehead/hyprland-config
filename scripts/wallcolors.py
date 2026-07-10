#!/usr/bin/env python3
"""
Generate the Quickshell pill palette from the current hyprpaper wallpaper.

The pill stays on fixed dark translucent neutrals for surfaces and text. Only
the highlight ramp uses the wallpaper's dominant chromatic hue. The output schema matches
~/.config/quickshell/pill/Singletons/Dyn.qml.
"""
import argparse
import colorsys
import json
import os
import re
import subprocess
import sys
from pathlib import Path

CACHE = Path(os.environ.get("XDG_CACHE_HOME", str(Path.home() / ".cache"))) / "ricelin"
DEFAULT_HYPRPAPER = Path.home() / ".config/hypr/hyprpaper.conf"

NEUTRALS = {
    "surface": "#151922",
    "surface_container_low": "#090b0f",
    "surface_container": "#0d1015",
    "surface_container_high": "#111419",
    "surface_container_highest": "#303640",
    "outline": "#8e8e8e",
    "outline_variant": "#343a42",
    "cream": "#e9ecef",
    "bright": "#ffffff",
    "subtle": "#c7cdd5",
    "dim": "#9ba3ad",
    "faint": "#737b86",
    "icon_dim": "#b6bec8",
    "tick_rest": "#8d96a3",
}

FALLBACK = {
    **NEUTRALS,
    "primary": "#d0d0d0",
    "primary_container": "#5a5a5a",
    "on_primary_container": "#f2f2f2",
}


def clamp(v):
    return max(0.0, min(1.0, v))


def hex_hls(hue, sat, light):
    r, g, b = colorsys.hls_to_rgb(hue % 1.0, clamp(light), clamp(sat))
    return "#%02x%02x%02x" % (round(r * 255), round(g * 255), round(b * 255))


def grey(light):
    return hex_hls(0.0, 0.0, light)


def lerp(x, x0, x1, y0, y1):
    t = clamp((x - x0) / (x1 - x0))
    return y0 + t * (y1 - y0)


def clean_path(value, base):
    value = value.strip().strip("\"'")
    if not value:
        return None
    path = Path(os.path.expandvars(os.path.expanduser(value)))
    if not path.is_absolute():
        path = base / path
    return path


def wallpaper_from_hyprpaper(conf):
    try:
        text = conf.read_text()
    except OSError:
        return None

    base = conf.parent
    wallpaper_candidates = []
    preload_candidates = []
    for line in text.splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        if "#" in stripped:
            stripped = stripped.split("#", 1)[0].strip()

        m = re.match(r"^path\s*=\s*(.+)$", stripped)
        if m:
            wallpaper_candidates.append(clean_path(m.group(1), base))
            continue

        m = re.match(r"^preload\s*=\s*(.+)$", stripped)
        if m:
            preload_candidates.append(clean_path(m.group(1), base))
            continue

        m = re.match(r"^wallpaper\s*=\s*[^,]+,\s*(.+)$", stripped)
        if m:
            wallpaper_candidates.append(clean_path(m.group(1), base))

    for path in wallpaper_candidates + preload_candidates:
        if path and path.is_file():
            return path
    return None


def analyze(wallpaper):
    try:
        out = subprocess.run(
            [
                "magick",
                str(wallpaper),
                "-alpha",
                "off",
                "-resize",
                "200x200",
                "-colors",
                "48",
                "-format",
                "%c",
                "histogram:info:-",
            ],
            capture_output=True,
            text=True,
            check=False,
        ).stdout
    except OSError:
        return None, 0.0, 0.12

    buckets = {}
    total = 0
    luminance = 0.0
    chroma = 0

    for line in out.splitlines():
        m = re.search(r"\s*(\d+):\s*\([^)]*\)\s*#([0-9A-Fa-f]{6})", line)
        if not m:
            continue
        count = int(m.group(1))
        hex_str = m.group(2)
        r, g, b = (int(hex_str[i:i + 2], 16) / 255 for i in (0, 2, 4))
        h, l, s = colorsys.rgb_to_hls(r, g, b)
        total += count
        luminance += count * l
        if s < 0.15 or l < 0.05 or l > 0.92:
            continue
        chroma += count
        bucket = buckets.setdefault((int(h * 360) // 30) % 12, {"wsat": 0.0, "best": None})
        bucket["wsat"] += count * s
        score = count * s * (1 if 0.12 < l < 0.55 else 0.4)
        if not bucket["best"] or score > bucket["best"][0]:
            bucket["best"] = (score, h, s)

    mean_l = luminance / total if total else 0.12
    if not buckets or chroma < 0.08 * total:
        return None, 0.0, mean_l

    win = max(buckets.values(), key=lambda v: v["wsat"])
    return win["best"][1], win["best"][2], mean_l


def build_palette(hue, sat, mean_l):
    chromatic = hue is not None
    if not chromatic:
        hue, sat = 0.0, 0.0

    acc_sat = min(max(sat, 0.30) + 0.12, 0.82) if chromatic else 0.0
    acc_l, deep_l, glow_l = 0.70, 0.34, 0.86
    pill = dict(NEUTRALS)
    pill["primary"] = hex_hls(hue, acc_sat, acc_l)
    pill["primary_container"] = hex_hls(hue, min(acc_sat + 0.08, 0.90), deep_l)
    pill["on_primary_container"] = hex_hls(hue, min(acc_sat, 0.45), glow_l)

    return pill


def write_palette(palette):
    CACHE.mkdir(parents=True, exist_ok=True)
    target = CACHE / "colors.json"
    tmp = target.with_suffix(".json.tmp")
    tmp.write_text(json.dumps(palette, indent=2) + "\n")
    tmp.replace(target)


def main():
    parser = argparse.ArgumentParser(description="Generate the Ricelin pill palette from hyprpaper.")
    parser.add_argument("wallpaper", nargs="?", help="Wallpaper image to sample directly.")
    parser.add_argument("--hyprpaper", default=str(DEFAULT_HYPRPAPER), help="hyprpaper.conf to read.")
    args = parser.parse_args()

    wallpaper = clean_path(args.wallpaper, Path.cwd()) if args.wallpaper else wallpaper_from_hyprpaper(Path(args.hyprpaper))
    if not wallpaper or not wallpaper.is_file():
        write_palette(FALLBACK)
        return 0

    hue, sat, mean_l = analyze(wallpaper)
    write_palette(build_palette(hue, sat, mean_l))
    return 0


if __name__ == "__main__":
    sys.exit(main())
