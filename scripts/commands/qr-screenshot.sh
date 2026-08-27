#!/bin/bash

# Decode a QR code from a screenshot region.
# Select a screen region, decode QR, put result on clipboard.
# QR codes can carry secrets (2FA setup codes), so the decoded value goes
# to the clipboard only — never stdout or notification history.
# Ported from: ~/src/omarchy/bin/omarchy-capture-qr
# Stripped: hyprpicker screen freeze overlay.


export PATH="$HOME/.local/bin:$PATH"
SELECTION=$(slurp 2>/dev/null)

[[ -z $SELECTION ]] && exit 0

# Decode QR codes only. Leaving other symbologies enabled lets dense screen
# content false-positive as an EAN or Code 39 barcode.
DECODED=$(grim -g "$SELECTION" - | zbarimg --raw -q --quiet - 2>/dev/null) || exit 1

[[ -z $DECODED ]] && exit 1

printf "%s" "$DECODED" | wl-copy
notify -g "QR code decoded to clipboard" -t 2000 2>/dev/null || true
