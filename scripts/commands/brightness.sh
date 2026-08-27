#!/bin/bash

# Show or adjust brightness on the focused display.
# Uses brightnessctl for backlight, ddcutil for external monitors.
# Ported from: ~/src/omarchy/bin/omarchy-brightness-display
# Stripped: hyprctl monitor detection, omarchy-osd, omarchy-hw-display.
# Uses /sys/class/backlight for device discovery and notify for feedback.

no_notify=0
monitor=""

while (( $# > 0 )); do
  case "$1" in
  --no-notify)
    no_notify=1
    shift
    ;;
  --monitor)
    (( $# >= 2 )) || exit 1
    monitor="$2"
    shift 2
    ;;
  *)
    break
    ;;
  esac
done

backlight_brightness() {
  brightnessctl -d "$1" -m 2>/dev/null | awk -F, '{ gsub("%", "", $4); print $4; found=1 } END{ exit !found }'
}

# Find the first backlight device
find_backlight_device() {
  for device in /sys/class/backlight/*; do
    [[ -e $device ]] && basename "$device" && return 0
  done
  return 1
}

if (( $# == 0 )); then
  device="$(find_backlight_device)" || exit 1
  backlight_brightness "$device"
  exit
fi

step="$1"

if [[ $step == "off" ]]; then
  # Sway equivalent: power off displays
  swaymsg output "*" power off 2>/dev/null || true
  exit 0
elif [[ $step == "on" ]]; then
  swaymsg output "*" power on 2>/dev/null || true
  exit 0
fi

# Drop overlapping brightness key events so concurrent invocations do not race.
exec {lock_fd}>"${XDG_RUNTIME_DIR:-/tmp}/brightness-display.lock"
flock -n "$lock_fd" || exit 0

device="$(find_backlight_device)" || exit 1
current=$(backlight_brightness "$device") || exit 1

# Apply non-uniform step size: 1% steps if at or below 5%, otherwise 5%.
if [[ $step == "+5%" ]]; then
  if (( current < 5 )); then
    (( target = current + 1 ))
  else
    (( target = current + 5 ))
  fi
  (( target > 100 )) && target=100
  step="$target%"
elif [[ $step == "5%-" ]]; then
  if (( current <= 5 )); then
    (( target = current - 1 ))
  else
    (( target = current - 5 ))
  fi
  (( target < 1 )) && target=1
  step="$target%"
fi

brightnessctl -d "$device" set "$step" >/dev/null

new_brightness=$(backlight_brightness "$device")
(( no_notify )) || notify -g "Brightness ${new_brightness}%" -t 1500 2>/dev/null || true
