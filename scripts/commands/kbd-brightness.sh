#!/bin/bash

# Adjust keyboard backlight brightness using available steps.
# Ported from: ~/src/omarchy/bin/omarchy-brightness-keyboard
# Stripped: omarchy-osd. Uses notify for optional feedback.

no_notify=0
if [[ ${1:-} == "--no-notify" ]]; then
  no_notify=1
  shift
fi

direction="${1:-up}"

device=""
for candidate in /sys/class/leds/*kbd_backlight*; do
  if [[ -e $candidate ]]; then
    device="$(basename "$candidate")"
    break
  fi
done

if [[ -z $device ]]; then
  echo "No keyboard backlight device found" >&2
  exit 1
fi

if [[ $direction == "off" ]]; then
  brightnessctl -sd "$device" set 0 >/dev/null
  exit 0
elif [[ $direction == "restore" ]]; then
  brightnessctl -rd "$device" >/dev/null
  exit 0
fi

max_brightness="$(brightnessctl -d "$device" max)"
current_brightness="$(brightnessctl -d "$device" get)"

step=$(( max_brightness / 10 ))
(( step < 1 )) && step=1

if [[ $direction == "cycle" ]]; then
  new_brightness=$(( current_brightness + step ))
  (( new_brightness > max_brightness )) && new_brightness=0
elif [[ $direction == "up" ]]; then
  new_brightness=$(( current_brightness + step ))
  (( new_brightness > max_brightness )) && new_brightness=$max_brightness
else
  new_brightness=$(( current_brightness - step ))
  (( new_brightness < 0 )) && new_brightness=0
fi

brightnessctl -d "$device" set "$new_brightness" >/dev/null
(( no_notify )) || notify -g "Keyboard brightness $(( new_brightness * 100 / max_brightness ))%" -t 1500 2>/dev/null || true
