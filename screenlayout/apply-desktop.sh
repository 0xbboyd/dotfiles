#!/usr/bin/env bash
# Apply the full i3 desktop surface in dependency order.
# Display geometry must settle before feh snapshots the root pixmap and before
# Polybar decides which monitors need bars.

set -euo pipefail

LAYOUT="$HOME/.screenlayout/auto.sh"
WALLPAPER="$HOME/.config/wallpapers/pixel-frontier-sunset-stockcake-1680x1050-focal.jpg"
POLYBAR_LAUNCH="$HOME/.config/polybar/launch.sh"

if [[ -x "$LAYOUT" ]]; then
  "$LAYOUT"
fi

# Give XRandR clients a short chance to observe the final screen geometry.
sleep 0.5

if command -v feh >/dev/null 2>&1 && [[ -f "$WALLPAPER" ]]; then
  feh --bg-fill "$WALLPAPER"
fi

if [[ -x "$POLYBAR_LAUNCH" ]]; then
  "$POLYBAR_LAUNCH"
fi
