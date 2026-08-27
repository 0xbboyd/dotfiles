#!/bin/bash

# Adjust output volume. Resolves through DSP sinks to the physical one.
# Ported from: ~/src/omarchy/bin/omarchy-audio-output-volume
# Stripped: omarchy-osd (Quickshell OSD). Uses notify for optional feedback.

action="${1:-}"

if [[ -z $action ]]; then
  echo "Usage: audio-volume <raise|lower|mute-toggle|+N|-N>"
  exit 1
fi

sink="$(audio-output-sink)"
if [[ -z $sink ]]; then
  echo "Could not resolve an audio sink to control." >&2
  exit  1
fi

volume_percent() {
  pactl get-sink-volume "$sink" 2>/dev/null |
    awk 'NR == 1 {
      for (i = 1; i <= NF; i++)
        if ($i ~ /%$/) {sub("%", "", $i); print $i; exit}
    }'
}

volume_muted() {
  [[ $(pactl get-sink-mute "$sink" 2>/dev/null) == *yes ]]
}

case "$action" in
  raise) action="+5" ;;
  lower) action="-5" ;;
esac

if [[ $action == "mute-toggle" ]]; then
  runtime_dir="${XDG_RUNTIME_DIR:-/tmp}"
  debounce_file="$runtime_dir/audio-volume-mute-toggle.last"
  now=$(date +%s%3N)
  last=0
  [[ -r $debounce_file ]] && read -r last <"$debounce_file" || true
  if ((now - last < 250)); then
    exit 0
  fi
  printf '%s\n' "$now" >"$debounce_file"

  pactl set-sink-mute "$sink" toggle
elif [[ $action =~ ^([+-])([0-9]+)$ ]]; then
  direction="${BASH_REMATCH[1]}"
  step="${BASH_REMATCH[2]}"

  current="$(volume_percent)"
  if [[ -z $current ]]; then
    echo "Could not read volume for $sink." >&2
    exit 1
  fi

  if [[ $direction == "+" ]]; then
    next=$((current + step))
    ((next <= 100)) || next=100
  else
    next=$((current - step))
    ((next >= 0)) || next=0
  fi

  pactl set-sink-mute "$sink" 0
  pactl set-sink-volume "$sink" "${next}%"
else
  echo "Unknown volume action: $action"
  exit 1
fi

percent=$(volume_percent)
if volume_muted || ((${percent:-0} == 0)); then
  notify -g "Volume muted" -t 1500 2>/dev/null || true
else
  notify -g "Volume ${percent}%" -t 1500 2>/dev/null || true
fi
