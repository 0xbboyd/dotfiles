#!/usr/bin/env bash
# Apply the full i3 desktop surface in dependency order.
# Display geometry must settle before feh snapshots the root pixmap and before
# Polybar decides which monitors need bars.

set -euo pipefail

LAYOUT="$HOME/.screenlayout/auto.sh"
WALLPAPER="$HOME/.config/wallpapers/pixel-frontier-sunset-stockcake-1680x1050-focal.jpg"
POLYBAR_LAUNCH="$HOME/.config/polybar/launch.sh"
GEOMETRY_STABLE_SAMPLES=3
GEOMETRY_MAX_ATTEMPTS=30
GEOMETRY_SAMPLE_DELAY=0.2

xrandr_geometry_signature() {
  # Keep only connected outputs and their current mode/position. This is the
  # state feh and Polybar care about. Sorting avoids false changes from output
  # ordering differences while XRandR events are still settling.
  xrandr --query | awk '
    / connected/ {
      mode = "off"
      for (i = 1; i <= NF; i++) {
        if ($i ~ /^[0-9]+x[0-9]+\+[0-9-]+\+[0-9-]+$/) {
          mode = $i
          break
        }
      }
      primary = ($3 == "primary") ? "primary" : "secondary"
      print $1, primary, mode
    }
  ' | sort
}

wait_for_geometry_stable() {
  local previous=""
  local current=""
  local stable_samples=0
  local attempt=1

  while (( attempt <= GEOMETRY_MAX_ATTEMPTS )); do
    current="$(xrandr_geometry_signature || true)"

    if [[ -n "$current" && "$current" == "$previous" ]]; then
      stable_samples=$((stable_samples + 1))
      if (( stable_samples >= GEOMETRY_STABLE_SAMPLES )); then
        return 0
      fi
    else
      stable_samples=1
      previous="$current"
    fi

    sleep "$GEOMETRY_SAMPLE_DELAY"
    attempt=$((attempt + 1))
  done

  printf 'apply-desktop.sh: XRandR geometry did not fully stabilize before timeout; continuing with latest geometry.\n' >&2
  printf '%s\n' "$current" >&2
  return 0
}

if [[ -x "$LAYOUT" ]]; then
  "$LAYOUT"
fi

wait_for_geometry_stable

if command -v feh >/dev/null 2>&1 && [[ -f "$WALLPAPER" ]]; then
  feh --bg-fill "$WALLPAPER"
fi

if [[ -x "$POLYBAR_LAUNCH" ]]; then
  "$POLYBAR_LAUNCH"
fi
