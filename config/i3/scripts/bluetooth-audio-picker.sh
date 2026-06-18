#!/usr/bin/env bash
set -euo pipefail

JBL_MAC="C4:A9:B8:CB:97:D9"
JBL_CARD="bluez_card.${JBL_MAC//:/_}"
JBL_LABEL="JBL Vibe Beam 2"

notify() {
  if command -v notify-send >/dev/null 2>&1; then
    notify-send "Bluetooth audio" "$1"
  else
    printf '%s\n' "$1" >&2
  fi
}

run_rofi() {
  rofi -dmenu -i -p "Audio/Bluetooth" -theme-str 'window { width: 42em; }'
}

card_exists() {
  pactl list cards short | awk '{print $2}' | grep -Fxq "$JBL_CARD"
}

connect_jbl() {
  bluetoothctl connect "$JBL_MAC" >/dev/null 2>&1 || true
  sleep 1
}

wait_for_jbl_sink() {
  local sink=""
  for _ in $(seq 1 20); do
    sink=$(pactl list short sinks | awk '/bluez_output\.C4_A9_B8_CB_97_D9/ {print $2; exit}')
    if [ -n "$sink" ]; then
      printf '%s\n' "$sink"
      return 0
    fi
    sleep 0.25
  done
  return 1
}

wait_for_jbl_source() {
  local source=""
  for _ in $(seq 1 20); do
    source=$(pactl list short sources | awk '/bluez_input\.C4_A9_B8_CB_97_D9/ {print $2; exit}')
    if [ -n "$source" ]; then
      printf '%s\n' "$source"
      return 0
    fi
    sleep 0.25
  done
  return 1
}

best_local_mic() {
  # Prefer the built-in/dock headset mic, then the digital mic, excluding monitor and Bluetooth sources.
  pactl list sources | awk '
    /^Source #/ { if (name && desc && name !~ /\.monitor$/ && name !~ /^bluez_/) print name "\t" desc; name=""; desc="" }
    /Name: / { name=$2 }
    /Description: / { sub(/^[[:space:]]*Description: /, ""); desc=$0 }
    END { if (name && desc && name !~ /\.monitor$/ && name !~ /^bluez_/) print name "\t" desc }
  ' | awk '
    /Headset Microphone/ { print $1; found=1; exit }
    /Digital Microphone/ { candidate=$1 }
    END { if (!found && candidate) print candidate }
  '
}

set_jbl_music() {
  connect_jbl
  card_exists || { notify "$JBL_LABEL is not available"; exit 1; }
  pactl set-card-profile "$JBL_CARD" a2dp-sink-sbc_xq 2>/dev/null || pactl set-card-profile "$JBL_CARD" a2dp-sink
  local sink
  sink=$(wait_for_jbl_sink) || { notify "JBL playback sink did not appear"; exit 1; }
  pactl set-default-sink "$sink"
  notify "$JBL_LABEL: music mode (A2DP/SBC-XQ), JBL mic disabled"
}

set_jbl_call() {
  connect_jbl
  card_exists || { notify "$JBL_LABEL is not available"; exit 1; }
  pactl set-card-profile "$JBL_CARD" headset-head-unit-msbc 2>/dev/null || pactl set-card-profile "$JBL_CARD" headset-head-unit
  local sink source
  sink=$(wait_for_jbl_sink) || { notify "JBL call playback sink did not appear"; exit 1; }
  source=$(wait_for_jbl_source) || { notify "JBL microphone source did not appear"; exit 1; }
  pactl set-default-sink "$sink"
  pactl set-default-source "$source"
  notify "$JBL_LABEL: call mode (JBL mic on, lower playback quality)"
}

set_jbl_music_local_mic() {
  set_jbl_music
  local mic
  mic=$(best_local_mic || true)
  if [ -n "$mic" ]; then
    pactl set-default-source "$mic"
    notify "$JBL_LABEL: music mode with local mic"
  else
    notify "$JBL_LABEL: music mode set; no local mic found"
  fi
}

choice=$(printf '%s\n' \
  "JBL music mode — best playback, no JBL mic" \
  "JBL call mode — JBL mic, lower playback quality" \
  "JBL music + local mic" \
  "Reconnect JBL" \
  "Open Bluetooth manager" \
  "Open audio mixer" \
  "Open Blueman applet" \
  | run_rofi)

case "$choice" in
  "JBL music mode"*) set_jbl_music ;;
  "JBL call mode"*) set_jbl_call ;;
  "JBL music + local mic"*) set_jbl_music_local_mic ;;
  "Reconnect JBL"*) connect_jbl; notify "Reconnect requested for $JBL_LABEL" ;;
  "Open Bluetooth manager"*) blueman-manager >/dev/null 2>&1 & ;;
  "Open audio mixer"*)
    if command -v pavucontrol >/dev/null 2>&1; then
      pavucontrol >/dev/null 2>&1 &
    else
      notify "pavucontrol is not installed; install it with: sudo apt install pavucontrol"
    fi
    ;;
  "Open Blueman applet"*) blueman-applet >/dev/null 2>&1 & ;;
  "") exit 0 ;;
  *) exit 0 ;;
esac
