#!/bin/bash

# Toggle microphone mute. Drives the hardware mic-mute LED on laptops that expose one.
# Ported from: ~/src/omarchy/bin/omarchy-audio-input-mute
# Stripped: omarchy-osd, omarchy-brightness-keyboard-mute. Uses notify for feedback.

wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle >/dev/null

if wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | grep -q MUTED; then
  # Try to set mic-mute LED on
  if [[ -e /sys/class/leds/platform::micmute/brightness ]]; then
    brightnessctl --device="platform::micmute" set 1 >/dev/null 2>&1 || true
  fi
  notify -g "Microphone muted" -t 1500 2>/dev/null || true
else
  if [[ -e /sys/class/leds/platform::micmute/brightness ]]; then
    brightnessctl --device="platform::micmute" set 0 >/dev/null 2>&1 || true
  fi
  notify -g "Microphone on" -t 1500 2>/dev/null || true
fi
