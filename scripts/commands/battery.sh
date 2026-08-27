#!/bin/bash

# Returns a formatted battery status string with percentage and power draw/charge.
# Ported from: ~/src/omarchy/bin/omarchy-battery-status
# No adaptation needed — uses upower and sysfs, no compositor dependencies.

shell_output=false
power_supply_path="${BATTERY_POWER_SUPPLY_PATH:-/sys/class/power_supply}"

case "${1:-}" in
  "")
    ;;
  --shell)
    shell_output=true
    ;;
  *)
    echo "Usage: battery-status [--shell]" >&2
    exit 2
    ;;
esac

battery=$(upower -e 2>/dev/null | grep BAT | head -n 1)
[[ -z $battery ]] && exit 0

battery_info=$(upower -i "$battery")

percentage=$(awk '/percentage/ { print int($2); exit }' <<<"$battery_info")
capacity=$(awk '/energy-full:/ { printf "%d", $2; exit }' <<<"$battery_info")
time_remaining=$(awk '/time to (empty|full)/ {
  value = $4
  unit = $5
  if (unit ~ /^minute/) {
    printf "%dm", int(value)
  } else {
    hours = int(value)
    minutes = int((value - hours) * 60)
    if (minutes > 0) {
      printf "%dh %dm", hours, minutes
    } else {
      printf "%dh", hours
    }
  }
  exit
}' <<<"$battery_info")
power_rate_raw=$(awk '/energy-rate/ { print $2; exit }' <<<"$battery_info")
native_path=$(awk '/native-path/ { print $2; exit }' <<<"$battery_info")
battery_path="$power_supply_path/$native_path"

if [[ -r $battery_path/power_now ]]; then
  power_rate_raw=$(awk -v microwatts="$(<"$battery_path/power_now")" 'BEGIN { print microwatts / 1000000 }')
elif [[ -r $battery_path/current_now && -r $battery_path/voltage_now ]]; then
  power_rate_raw=$(awk \
    -v microamps="$(<"$battery_path/current_now")" \
    -v microvolts="$(<"$battery_path/voltage_now")" \
    'BEGIN { print microamps * microvolts / 1000000000000 }')
fi

power_rate=$(awk -v rate="${power_rate_raw:-0}" 'BEGIN {
  rounded = sprintf("%.1f", rate)
  sub(/\.0$/, "", rounded)
  print rounded
}')
state=$(awk '/state/ { print $2; exit }' <<<"$battery_info")

if [[ $shell_output == "true" ]]; then
  printf 'percentage\t%s\n' "${percentage}%"
  printf 'state\t%s\n' "$state"
  printf 'rate\t%s\n' "${power_rate}W"
  printf 'size\t%s\n' "${capacity}Wh"
  printf 'time\t%s\n' "$time_remaining"

  cycles=$(cat "$power_supply_path"/BAT*/cycle_count 2>/dev/null | head -1)
  [[ -n $cycles ]] && printf 'cycles\t%s\n' "$cycles"

  exit 0
fi

if [[ $state == "charging" ]]; then
  echo "Battery ${percentage}%  ·  ${time_remaining} to full  ·  ${power_rate}W / ${capacity}Wh"
else
  echo "Battery ${percentage}%  ·  ${time_remaining} left  ·  ${power_rate}W / ${capacity}Wh"
fi
