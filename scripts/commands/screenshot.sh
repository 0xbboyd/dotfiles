#!/bin/bash

# Take a screenshot with grim + slurp (Wayland-native).
# Modes: smart (region select), region, fullscreen
# Output: slurp (clipboard+file+editor), copy (clipboard only), save (file only)
# Ported from: ~/src/omarchy/bin/omarchy-capture-screenshot
# Stripped: hyprpicker screen freeze, hyprctl hardware cursor workaround.

[[ -f ~/.config/user-dirs.dirs ]] && source ~/.config/user-dirs.dirs
OUTPUT_DIR="${SCREENSHOT_DIR:-${XDG_PICTURES_DIR:-$HOME/Pictures}}"

if [[ ! -d $OUTPUT_DIR ]]; then
  mkdir -p "$OUTPUT_DIR"
  notify "Created screenshot directory: $OUTPUT_DIR" -t 2000 2>/dev/null || true
fi

pkill slurp && exit 0

SCREENSHOT_EDITOR="${SCREENSHOT_EDITOR:-swappy}"

# Parse --editor flag from any position
ARGS=()
for arg in "$@"; do
  if [[ $arg == --editor=* ]]; then
    SCREENSHOT_EDITOR="${arg#--editor=}"
  else
    ARGS+=("$arg")
  fi
done
set -- "${ARGS[@]}"

MODE="${1:-smart}"
PROCESSING="${2:-slurp}"

# Get selection geometry
get_selection() {
  local mode="$1"

  case "$mode" in
    fullscreen)
      # Grab the focused output's geometry
      local output
      output=$(swaymsg -t get_outputs -r 2>/dev/null | jq -r '.[] | select(.focused) | .name')
      if [[ -n $output ]]; then
        swaymsg -t get_outputs -r 2>/dev/null | jq -r --arg o "$output" '
          .[] | select(.name == $o) |
          "\(.rect.x),\(.rect.y) \(.rect.width)x\(.rect.height)"'
      else
        # Fallback: grab all outputs
        grim -t png - | wl-copy --type image/png
        exit 0
      fi
      ;;
    region|smart|*)
      slurp -d 2>/dev/null
      ;;
  esac
}

SELECTION=$(get_selection "$MODE")

[[ -z $SELECTION ]] && exit 0

FILENAME="screenshot-$(date +'%Y-%m-%d_%H-%M-%S').png"
FILEPATH="$OUTPUT_DIR/$FILENAME"

case "$PROCESSING" in
  slurp)
    grim -g "$SELECTION" "$FILEPATH" || exit 1
    echo "$FILEPATH"
    wl-copy --type image/png <"$FILEPATH"
    notify "Screenshot saved" "Clipboard + $FILEPATH" \
      --image "$FILEPATH" --exec "$SCREENSHOT_EDITOR" -f "$FILEPATH" -t 5000 2>/dev/null || true
    ;;
  copy)
    grim -g "$SELECTION" - | wl-copy --type image/png
    ;;
  save)
    grim -g "$SELECTION" "$FILEPATH" || exit 1
    echo "$FILEPATH"
    ;;
esac
