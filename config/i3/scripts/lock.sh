#!/usr/bin/env bash
set -euo pipefail

# Yendo Cowboy i3 lock screen.
# Generates a non-live-desktop lock image, then hands it to stock i3lock.
# Default style: pure Yendo Cowboy gradient per monitor.
# Optional alternate: blurred managed wallpaper per monitor via LOCK_STYLE=wallpaper.

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/i3lock"
LOCK_IMG="$CACHE_DIR/screen-lock.png"
PALETTE="$HOME/src/dotfiles/config/yendo-cowboy/palette.yaml"
WALLPAPER="$HOME/.config/wallpapers/pixel-frontier-sunset-stockcake-1680x1050-focal.jpg"
DISPLAY_VALUE="${DISPLAY:-:0}"
LOCK_STYLE="${LOCK_STYLE:-gradient}"
MODE="${1:-}"
LOCK_PID_FILE="${XDG_RUNTIME_DIR:-/tmp}/i3lock-yendo.pid"

mkdir -p "$CACHE_DIR"

if [[ "$MODE" != "--preview" ]]; then
    if [[ -s "$LOCK_PID_FILE" ]]; then
        existing_pid="$(cat "$LOCK_PID_FILE" 2>/dev/null || true)"
        if [[ "$existing_pid" =~ ^[0-9]+$ ]] && kill -0 "$existing_pid" 2>/dev/null; then
            exit 0
        fi
    fi
    printf '%s\n' "$$" > "$LOCK_PID_FILE"
    trap 'rm -f "$LOCK_PID_FILE"' EXIT
fi

fallback_lock() {
    if [[ "$MODE" == "--preview" ]]; then
        printf '%s\n' "preview generation failed"
        return 1
    fi
    exec i3lock -n -c 1a0f0a
}

render_lock_image() {
    DISPLAY="$DISPLAY_VALUE" python3 - "$LOCK_IMG" "$PALETTE" "$WALLPAPER" "$LOCK_STYLE" <<'PY'
from __future__ import annotations

import datetime as dt
import getpass
import math
import os
import re
import socket
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageFont

out_path = Path(sys.argv[1])
palette_path = Path(sys.argv[2])
wallpaper_path = Path(sys.argv[3])
lock_style = sys.argv[4].strip().lower()

def load_palette(path: Path) -> dict[str, str]:
    defaults = {
        'bg': '#1a0f0a',
        'bg_darker': '#0d0704',
        'bg_mid': '#2d1810',
        'fg': '#fff5e1',
        'primary': '#e87530',
        'accent': '#f5a623',
        'border': '#c4522a',
        'dim': '#8b4513',
        'muted': '#a0522d',
        'error': '#ef5350',
    }
    if not path.exists():
        return defaults
    for line in path.read_text().splitlines():
        if ':' not in line or line.lstrip().startswith('#'):
            continue
        key, value = line.split(':', 1)
        value = value.strip().strip('"').strip("'")
        if value.startswith('#'):
            defaults[key.strip()] = value
    return defaults

def hex_rgba(color: str, alpha: int = 255) -> tuple[int, int, int, int]:
    color = color.lstrip('#')
    return tuple(int(color[i:i+2], 16) for i in (0, 2, 4)) + (alpha,)

def font(size: int, bold: bool = False):
    candidates = [
        '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf' if bold else '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
        '/usr/share/fonts/truetype/liberation2/LiberationSans-Bold.ttf' if bold else '/usr/share/fonts/truetype/liberation2/LiberationSans-Regular.ttf',
    ]
    for candidate in candidates:
        if Path(candidate).exists():
            return ImageFont.truetype(candidate, size=size)
    return ImageFont.load_default()

def text_center(draw: ImageDraw.ImageDraw, xy: tuple[int, int], text: str, fnt, fill):
    bbox = draw.textbbox((0, 0), text, font=fnt)
    text_w = bbox[2] - bbox[0]
    text_h = bbox[3] - bbox[1]
    draw.text((xy[0] - text_w / 2, xy[1] - text_h / 2), text, font=fnt, fill=fill)

def root_size() -> tuple[int, int]:
    try:
        output = subprocess.check_output(
            ['xdpyinfo'],
            text=True,
            stderr=subprocess.DEVNULL,
            env={**os.environ, 'DISPLAY': os.environ.get('DISPLAY', ':0')},
            timeout=2,
        )
        match = re.search(r'dimensions:\s+(\d+)x(\d+) pixels', output)
        if match:
            return int(match.group(1)), int(match.group(2))
    except Exception:
        pass
    return 1920, 1080

def connected_monitors(fallback_size: tuple[int, int]) -> list[dict[str, int | str]]:
    """Return XRandR monitor rectangles in root-window coordinates."""
    try:
        output = subprocess.check_output(
            ['xrandr', '--listmonitors'],
            text=True,
            stderr=subprocess.DEVNULL,
            env={**os.environ, 'DISPLAY': os.environ.get('DISPLAY', ':0')},
            timeout=2,
        )
    except Exception:
        return [{'name': 'display', 'x': 0, 'y': 0, 'w': fallback_size[0], 'h': fallback_size[1]}]

    monitors = []
    # Example: " 0: +*eDP-1 1680/300x1050/190+1920+0  eDP-1"
    pattern = re.compile(r'\s*\d+:\s+\S+\s+(\d+)/\d+x(\d+)/\d+([+-]\d+)([+-]\d+)\s+(\S+)')
    for line in output.splitlines():
        match = pattern.match(line)
        if not match:
            continue
        monitor_w, monitor_h, monitor_x, monitor_y, name = match.groups()
        monitors.append({'name': name, 'x': int(monitor_x), 'y': int(monitor_y), 'w': int(monitor_w), 'h': int(monitor_h)})

    if not monitors:
        return [{'name': 'display', 'x': 0, 'y': 0, 'w': fallback_size[0], 'h': fallback_size[1]}]
    return monitors

def cover_resize(src: Image.Image, target_w: int, target_h: int) -> Image.Image:
    src_w, src_h = src.size
    scale = max(target_w / src_w, target_h / src_h)
    resized = src.resize((math.ceil(src_w * scale), math.ceil(src_h * scale)), Image.Resampling.LANCZOS)
    left = max(0, (resized.width - target_w) // 2)
    top = max(0, (resized.height - target_h) // 2)
    return resized.crop((left, top, left + target_w, top + target_h))

def vertical_gradient(size: tuple[int, int], top, middle, bottom) -> Image.Image:
    width, height = size
    img = Image.new('RGBA', size)
    pixels = img.load()
    for y in range(height):
        t = y / max(1, height - 1)
        if t < 0.55:
            p = t / 0.55
            c1, c2 = top, middle
        else:
            p = (t - 0.55) / 0.45
            c1, c2 = middle, bottom
        color = tuple(int(c1[i] * (1 - p) + c2[i] * p) for i in range(4))
        for x in range(width):
            pixels[x, y] = color
    return img

def monitor_background(monitor_w: int, monitor_h: int, pal: dict[str, str], wallpaper: Image.Image | None) -> Image.Image:
    if wallpaper is not None:
        bg = cover_resize(wallpaper, monitor_w, monitor_h).convert('RGBA')
        bg = bg.filter(ImageFilter.GaussianBlur(radius=max(14, min(monitor_w, monitor_h) // 55)))
        bg = ImageEnhance.Brightness(bg).enhance(0.58)
        bg = ImageEnhance.Color(bg).enhance(0.86)
        bg = Image.alpha_composite(bg, Image.new('RGBA', (monitor_w, monitor_h), hex_rgba(pal['bg_darker'], 95)))
        return bg

    bg = vertical_gradient(
        (monitor_w, monitor_h),
        hex_rgba(pal['bg_darker']),
        hex_rgba(pal['bg']),
        hex_rgba(pal['bg_mid']),
    )
    gd = ImageDraw.Draw(bg)
    # Subtle sunset glow and diagonal leather banding; pure generated, no live desktop content.
    glow = Image.new('RGBA', (monitor_w, monitor_h), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow)
    glow_r = int(max(monitor_w, monitor_h) * 0.58)
    glow_x = int(monitor_w * 0.50)
    glow_y = int(monitor_h * 0.18)
    for r in range(glow_r, 0, -28):
        alpha = int(55 * (1 - r / glow_r) ** 2)
        glow_draw.ellipse((glow_x-r, glow_y-r, glow_x+r, glow_y+r), fill=hex_rgba(pal['primary'], alpha))
    bg = Image.alpha_composite(bg, glow)
    gd = ImageDraw.Draw(bg)
    for offset in range(-monitor_h, monitor_w, 190):
        gd.line((offset, monitor_h, offset + monitor_h, 0), fill=hex_rgba(pal['border'], 28), width=2)
    return bg

def apply_monitor_vignette(base: Image.Image, monitor: dict[str, int | str]) -> Image.Image:
    x, y, monitor_w, monitor_h = int(monitor['x']), int(monitor['y']), int(monitor['w']), int(monitor['h'])
    layer = Image.new('RGBA', base.size, (0, 0, 0, 0))
    alpha = Image.new('L', (monitor_w, monitor_h), 0)
    alpha_draw = ImageDraw.Draw(alpha)
    max_radius = math.sqrt((monitor_w / 2) ** 2 + (monitor_h / 2) ** 2)
    for radius in range(int(max_radius), 0, -20):
        value = int(125 * (1 - radius / max_radius) ** 2)
        alpha_draw.ellipse((monitor_w/2-radius, monitor_h/2-radius, monitor_w/2+radius, monitor_h/2+radius), fill=value)
    vignette = Image.merge('RGBA', [Image.new('L', (monitor_w, monitor_h), 0)] * 3 + [alpha])
    layer.alpha_composite(vignette, dest=(x, y))
    return Image.alpha_composite(base, layer)

def draw_lock_panel(draw: ImageDraw.ImageDraw, monitor: dict[str, int | str], pal: dict[str, str], time_text: str, date_text: str, user_text: str):
    x, y, monitor_w, monitor_h = int(monitor['x']), int(monitor['y']), int(monitor['w']), int(monitor['h'])
    center_x = x + monitor_w // 2
    center_y = y + monitor_h // 2

    scale = max(0.82, min(1.0, monitor_w / 1920, monitor_h / 1080))
    panel_w = min(int(700 * scale), int(monitor_w * 0.72))
    panel_h = int(286 * scale)
    panel = (
        center_x - panel_w // 2,
        center_y - panel_h // 2,
        center_x + panel_w // 2,
        center_y + panel_h // 2,
    )

    radius = int(30 * scale)
    draw.rounded_rectangle(panel, radius=radius, fill=hex_rgba(pal['bg'], 184), outline=hex_rgba(pal['primary'], 218), width=max(2, int(3 * scale)))
    inset = int(11 * scale)
    draw.rounded_rectangle((panel[0] + inset, panel[1] + inset, panel[2] - inset, panel[3] - inset), radius=max(18, radius - 8), outline=hex_rgba(pal['border'], 135), width=1)

    mark_y = panel[1] + int(50 * scale)
    line_outer = int(170 * scale)
    line_inner = int(42 * scale)
    sun_radius = int(22 * scale)
    draw.line((center_x - line_outer, mark_y, center_x - line_inner, mark_y), fill=hex_rgba(pal['muted'], 220), width=max(1, int(2 * scale)))
    draw.line((center_x + line_inner, mark_y, center_x + line_outer, mark_y), fill=hex_rgba(pal['muted'], 220), width=max(1, int(2 * scale)))
    draw.ellipse((center_x - sun_radius, mark_y - sun_radius, center_x + sun_radius, mark_y + sun_radius), outline=hex_rgba(pal['accent'], 240), width=max(2, int(3 * scale)))

    text_center(draw, (center_x, panel[1] + int(113 * scale)), time_text, font(int(62 * scale), True), hex_rgba(pal['primary']))
    text_center(draw, (center_x, panel[1] + int(174 * scale)), date_text, font(int(24 * scale)), hex_rgba(pal['fg'], 240))
    text_center(draw, (center_x, panel[1] + int(219 * scale)), 'locked // enter password to ride on', font(int(17 * scale)), hex_rgba(pal['accent'], 234))
    text_center(draw, (center_x, panel[1] + int(253 * scale)), user_text, font(int(14 * scale)), hex_rgba(pal['muted'], 235))

pal = load_palette(palette_path)
root_w, root_h = root_size()
monitors = connected_monitors((root_w, root_h))

wallpaper = None
if lock_style != 'gradient' and wallpaper_path.exists():
    try:
        wallpaper = Image.open(wallpaper_path).convert('RGB')
    except Exception:
        wallpaper = None

canvas = Image.new('RGBA', (root_w, root_h), hex_rgba(pal['bg_darker']))
for monitor in monitors:
    x, y, monitor_w, monitor_h = int(monitor['x']), int(monitor['y']), int(monitor['w']), int(monitor['h'])
    bg = monitor_background(monitor_w, monitor_h, pal, wallpaper)
    canvas.alpha_composite(bg, dest=(x, y))
    canvas = apply_monitor_vignette(canvas, monitor)

draw = ImageDraw.Draw(canvas)
now = dt.datetime.now()
time_text = now.strftime('%I:%M %p').lstrip('0')
date_text = now.strftime('%A, %B %d')
user_text = f'{getpass.getuser()}@{socket.gethostname().split(".")[0]}'

for monitor in monitors:
    draw_lock_panel(draw, monitor, pal, time_text, date_text, user_text)

canvas.convert('RGB').save(out_path, optimize=True)
print(out_path)
PY
}

if ! render_lock_image; then
    fallback_lock
fi

if [[ "$MODE" == "--preview" ]]; then
    printf '%s\n' "$LOCK_IMG"
    exit 0
fi

exec i3lock -n -i "$LOCK_IMG"
