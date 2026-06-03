#!/usr/bin/env bash
set -euo pipefail

CONFIG="$HOME/.config/polybar/config.ini"

# Stop existing Polybar instances started by this user.
polybar-msg cmd quit >/dev/null 2>&1 || true
pkill -x polybar >/dev/null 2>&1 || true

# Let X release old bar/tray windows before relaunching.
sleep 0.3

# Launch one bar per connected monitor. The primary monitor gets the only tray.
mapfile -t monitor_lines < <(polybar --list-monitors)
primary_monitor=""

for line in "${monitor_lines[@]}"; do
  if [[ "$line" == *"primary"* ]]; then
    primary_monitor="${line%%:*}"
    break
  fi
done

# Fallback: if XRandR reports no primary monitor, put the tray on the first bar only.
if [[ -z "$primary_monitor" && "${#monitor_lines[@]}" -gt 0 ]]; then
  primary_monitor="${monitor_lines[0]%%:*}"
fi

for line in "${monitor_lines[@]}"; do
  monitor="${line%%:*}"
  [ -n "$monitor" ] || continue

  bar="yendo"
  if [[ "$monitor" == "$primary_monitor" ]]; then
    bar="yendo-primary"
  fi

  MONITOR="$monitor" polybar --reload "$bar" --config="$CONFIG" >/tmp/polybar-${monitor}.log 2>&1 &
done
