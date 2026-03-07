#!/usr/bin/env bash

# Check if wl-paste is installed
if ! command -v wl-paste &> /dev/null; then
    echo "Error: wl-paste (wl-clipboard) is not installed. Run 'sudo apt install wl-clipboard' to fix."
    exit 1
fi

# Create a unique temp file
TEMP_FILE="/tmp/clip_image_$(date +%s).png"

# Attempt to save clipboard image to file
if wl-paste -t image/png > "$TEMP_FILE" 2>/dev/null; then
    echo "$TEMP_FILE"
else
    echo "Error: No image found in clipboard."
    rm -f "$TEMP_FILE"
    exit 1
fi
