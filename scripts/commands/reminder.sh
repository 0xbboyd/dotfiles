#!/bin/bash

# Set and show lightweight desktop notification reminders.
# Uses systemd user timers for reliability. Reminders survive shell exits.
# Ported from: ~/src/omarchy/bin/omarchy-reminder


export PATH="$HOME/.local/bin:$PATH"
set -euo pipefail

format_remaining() {
  local seconds=$1
  local minutes=$((seconds / 60))
  local remainder=$((seconds % 60))

  if ((minutes > 0 && remainder > 0)); then
    echo "${minutes}m ${remainder}s"
  elif ((minutes > 0)); then
    echo "${minutes}m"
  else
    echo "${remainder}s"
  fi
}

active_reminder_timers() {
  local now=${1:-$(date +%s)}
  local timer next

  while IFS=$'\t' read -r timer next; do
    [[ -z $timer || -z $next ]] && continue

    next=$((next / 1000000))
    ((next <= now)) && continue

    printf "%s\t%s\n" "$timer" "$next"
  done < <(systemctl --user list-timers --all --output=json "reminder-*.timer" 2>/dev/null | jq -r '.[] | [.unit, .next] | @tsv')
}

show_reminders() {
  local timer next remaining reminder reminder_minutes body=""
  local reminder_dir="${XDG_RUNTIME_DIR:-/tmp}/reminders"
  local reminder_message=""
  local now=$(date +%s)

  while IFS=$'\t' read -r timer next; do
    remaining=$((next - now))
    reminder=${timer%.timer}
    reminder=${reminder#reminder-}
    reminder_minutes=${reminder%%m-*}
    reminder_message=""
    [[ -f $reminder_dir/${timer%.timer}.message ]] && reminder_message=$(<"$reminder_dir/${timer%.timer}.message")

    if [[ -n $reminder_message ]]; then
      body+="$reminder_message in $(format_remaining $remaining) ($(date -d "@$next" +%-H:%M))"$'\n'
    else
      body+="${reminder_minutes}-min reminder in $(format_remaining $remaining) ($(date -d "@$next" +%-H:%M))"$'\n'
    fi
  done < <(active_reminder_timers "$now")

  if [[ -z $body ]]; then
    notify -g "Upcoming reminders" "No outstanding reminders"
  else
    notify -g "Upcoming reminders" "${body%$'\n'}"
  fi
}

show_json() {
  local timer next remaining reminder reminder_minutes unit reminder_message label item_json reminders_json="[]"
  local reminder_dir="${XDG_RUNTIME_DIR:-/tmp}/reminders"
  local now=$(date +%s)
  local count=0
  local tooltip="Set Reminder"

  while IFS=$'\t' read -r timer next; do
    count=$((count + 1))

    unit=${timer%.timer}
    reminder=${unit#reminder-}
    reminder_minutes=${reminder%%m-*}
    [[ ! $reminder_minutes =~ ^[0-9]+$ ]] && reminder_minutes=0
    remaining=$((next - now))
    reminder_message=""
    [[ -f $reminder_dir/$unit.message ]] && reminder_message=$(<"$reminder_dir/$unit.message")

    if [[ -n $reminder_message ]]; then
      label=$reminder_message
    else
      label="${reminder_minutes}-min reminder"
    fi

    item_json=$(jq -nc \
      --arg unit "$unit" \
      --arg timer "$timer" \
      --arg label "$label" \
      --arg message "$reminder_message" \
      --arg remaining "$(format_remaining "$remaining")" \
      --arg atTime "$(date -d "@$next" +%-H:%M)" \
      --argjson minutes "$reminder_minutes" \
      --argjson at "$next" \
      --argjson remainingSeconds "$remaining" \
      '{unit:$unit,timer:$timer,minutes:$minutes,message:$message,label:$label,remaining:$remaining,remainingSeconds:$remainingSeconds,at:$at,atTime:$atTime}')
    reminders_json=$(jq -nc --argjson reminders "$reminders_json" --argjson item "$item_json" '$reminders + [$item]')
  done < <(active_reminder_timers "$now")

  if ((count == 1)); then
    tooltip="1 reminder"
  elif ((count > 1)); then
    tooltip="$count reminders"
  fi

  jq -nc --argjson count "$count" --arg tooltip "$tooltip" --argjson reminders "$reminders_json" '{count:$count,active:($count > 0),tooltip:$tooltip,reminders:$reminders}'
}

clear_reminders() {
  local units
  local reminder_dir="${XDG_RUNTIME_DIR:-/tmp}/reminders"

  # Only stop the .timer units — the .service units may not be loaded yet
  # (systemd-run --on-active creates a transient timer; the service only
  # loads when the timer fires). Stopping a non-existent service fails and
  # would abort the clear under set -e.
  units=$(systemctl --user list-timers --all --no-legend --no-pager "reminder-*.timer" 2>/dev/null | awk '{ print $(NF - 1) }')

  if [[ -n $units ]]; then
    xargs -r systemctl --user stop <<<"$units" 2>/dev/null || true
  fi

  rm -f "$reminder_dir"/reminder-*.message 2>/dev/null || true
  notify -g "All reminders have been cleared" 2>/dev/null || true
}

usage() {
  echo "Usage: reminder [-i|--interactive]"
  echo "       reminder <minutes> [message]"
  echo "       reminder show [-j|--json]"
  echo "       reminder clear"
}

case ${1:-} in
show | list)
  case ${2:-} in
  -j | --json)
    show_json
    ;;
  "")
    show_reminders
    ;;
  *)
    usage
    exit 1
    ;;
  esac
  exit 0
  ;;
clear)
  clear_reminders
  exit 0
  ;;
esac

minutes=${1:-}
shift || true
message="$*"
custom_message="$message"

if [[ -z $minutes ]] || [[ ! $minutes =~ ^[0-9]+$ ]] || ((minutes == 0)); then
  usage
  exit 1
fi

if [[ -z $message ]]; then
  message="Your ${minutes} minutes are up"
fi

set_at=$(date +%s)
remind_at=$(date -d "+${minutes} minutes" +%H:%M)
unit="reminder-${minutes}m-$set_at"
reminder_dir="${XDG_RUNTIME_DIR:-/tmp}/reminders"
message_file="$reminder_dir/$unit.message"
confirmation="You'll be reminded at $remind_at"
confirmation_title="Reminder set for ${minutes} minutes"

mkdir -p "$reminder_dir"

if [[ -n $custom_message ]]; then
  printf "%s" "$custom_message" >"$message_file"
  confirmation_title="$custom_message in ${minutes} minutes"
fi

systemd-run --user --quiet --collect --on-active="${minutes}m" --unit="$unit" \
  bash -c 'notify -g "Reminder" "$1"; rm -f "$2"' bash "$message" "$message_file"

notify -g "$confirmation_title" "$confirmation"
