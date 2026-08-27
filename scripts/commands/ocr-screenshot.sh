#!/bin/bash

# Extract text from a screenshot region with OCR (tesseract).
# Select a screen region, run OCR, put text on clipboard.
# Ported from: ~/src/omarchy/bin/omarchy-capture-text
# Stripped: hyprpicker screen freeze overlay.

SELECTION=$(slurp 2>/dev/null)

[[ -z $SELECTION ]] && exit 0

TEXT=$(grim -g "$SELECTION" - | tesseract stdin stdout --oem 1 --psm 6 -l "${OCR_LANGS:-eng}" --dpi 300 -c preserve_interword_spaces=1 2>/dev/null) || exit 1

[[ -z $TEXT ]] && exit 1

printf "%s" "$TEXT" | wl-copy
notify -g "OCR text copied to clipboard" -t 2000 2>/dev/null || true
