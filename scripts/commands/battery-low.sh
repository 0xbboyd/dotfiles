#!/bin/bash

# Send the low battery warning notification.
# Ported from: ~/src/omarchy/bin/omarchy-battery-low
# Stripped: omarchy-hook. Uses notify instead of omarchy-notification-send.

set -euo pipefail

if (($# != 1)); then
  echo "Usage: battery-low <percentage>" >&2
  exit 1
fi

level=$1

notify -g "Time to recharge!" -u critical "Battery is down to ${level}%" -t 30000 2>/dev/null || true
