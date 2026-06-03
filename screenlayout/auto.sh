#!/usr/bin/env sh
# Auto-select display layout for i3/X11.
# Prefer autorandr if installed/configured; otherwise fall back to simple HDMI detection.

set -eu

if command -v autorandr >/dev/null 2>&1; then
  # --change applies the first matching saved profile.
  # Suppress Ubuntu 24.04/Python SyntaxWarning noise from autorandr 1.14.
  # If no profile matches, continue to the fallback below.
  PYTHONWARNINGS=ignore autorandr --change && exit 0
fi

if xrandr --query | grep -q '^HDMI-1 connected'; then
  exec "$HOME/.screenlayout/layout.sh"
fi

# Laptop-only fallback. Keep the same laptop resolution you saved in arandr so
# text size stays consistent with your dual-monitor profile.
xrandr \
  --output eDP-1 --primary --mode 1680x1050 --pos 0x0 --rotate normal \
  --output HDMI-1 --off \
  --output DP-1 --off \
  --output DP-2 --off \
  --output DP-1-1-5 --off
