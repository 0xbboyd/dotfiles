#!/bin/bash

# Switch between audio outputs while preserving mute status.
# Ported from: ~/src/omarchy/bin/omarchy-audio-output-switch
# Stripped: omarchy-audio-tuning fronted-sink resolution, omarchy-osd.

sinks=$(timeout 2 pactl -f json list sinks |
  jq '[.[]
    | select((.ports | length == 0) or ([.ports[]? | .availability != "not available"] | any))]')

sinks_count=$(jq 'length' <<<"$sinks")

if (( sinks_count == 0 )); then
  notify -g "No audio devices found" -t 2000 2>/dev/null || true
  exit 1
fi

current_sink_name=$(timeout 2 pactl get-default-sink)
current_sink_index=$(jq -r --arg name "$current_sink_name" 'map(.name) | index($name)' <<<"$sinks")

if [[ $current_sink_index != "null" ]]; then
  next_sink_index=$(((current_sink_index + 1) % sinks_count))
else
  next_sink_index=0
fi

next_sink=$(jq -c ".[$next_sink_index]" <<<"$sinks")
next_sink_name=$(jq -r '.name' <<<"$next_sink")
next_sink_description=$(jq -r '.description // .properties."device.description" // .name' <<<"$next_sink")
next_sink_index_num=$(jq -r '.index' <<<"$next_sink")

if [[ $next_sink_name != $current_sink_name ]]; then
  timeout 2 wpctl set-default "$next_sink_index_num" 2>/dev/null || true
  timeout 2 pactl set-default-sink "$next_sink_name" 2>/dev/null || true
  timeout 2 pactl list sink-inputs 2>/dev/null | awk '{ print $1 }' | while read -r input; do
    [[ -n $input ]] && timeout 2 pactl move-sink-input "$input" "$next_sink_name" 2>/dev/null || true
  done
fi

notify -g "Audio output" "$next_sink_description" -t 3000 2>/dev/null || true
