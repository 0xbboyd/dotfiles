#!/usr/bin/env bash
# Restart waybar cleanly.
#
# Why this exists: the old inline `exec ... $(ls /run/user/$(id -u)/sway-ipc.*.sock | head -1) waybar`
# in the sway config had two failure modes:
#   1. `ls` honors shell aliases — an alias that prepends Nerd-Font icons once
#      polluted SWAYSOCK with a leading glyph and waybar's sway/* modules
#      silently failed to connect to IPC.
#   2. `waybar &` inside the session/keybind dies with its parent shell, leaving
#      no bar and no log.
# This script globs for the socket, verifies it with swaymsg, waits for the old
# bar to die (zombies don't count), and relaunches detached via setsid with the
# theme switcher's generated CSS when present.
set -u

SWAYSOCK=""
for sock in /run/user/"$(id -u)"/sway-ipc.*.sock; do
	[[ -S $sock ]] || continue
	if swaymsg -s "$sock" -t get_version >/dev/null 2>&1; then
		SWAYSOCK="$sock"
		break
	fi
done
if [[ -z $SWAYSOCK ]]; then
	echo "waybar-restart: no live sway IPC socket found" >&2
	exit 1
fi
export SWAYSOCK

# Prefer the theme switcher's generated CSS; fall back to the repo style.
CSS="$HOME/.local/state/theme-current/waybar-style.css"
[[ -f $CSS ]] || CSS="$HOME/.config/waybar/style.css"

pkill -x waybar 2>/dev/null || true

# Wait for any LIVE waybar to exit. Zombies (state Z) still show in pgrep but
# hold no resources; don't wait on them.
waybar_alive=false
for _ in $(seq 1 20); do
	waybar_alive=false
	for pid in $(pgrep -x waybar); do
		state=$(ps -o stat= -p "$pid" 2>/dev/null) || continue
		if [[ $state != Z* ]]; then
			waybar_alive=true
			break
		fi
	done
	$waybar_alive || break
	sleep 0.1
done
if $waybar_alive; then
	pkill -9 -x waybar 2>/dev/null || true
	sleep 0.2
fi

# setsid detaches from the calling session so the bar survives parent exit.
setsid waybar -c "$HOME/.config/waybar/config" -s "$CSS" >/dev/null 2>&1 </dev/null &
disown 2>/dev/null || true
