#!/usr/bin/env bash

# Check if xclip is installed
if ! command -v xclip &> /dev/null; then
    echo "Error: xclip is not installed. Run 'sudo apt install xclip' to fix."
    exit 1
fi

# Create a unique temp file
TEMP_FILE="/tmp/clip_image_$(date +%s).png"

# Attempt to save clipboard image to file
if xclip -selection clipboard -t image/png -o > "$TEMP_FILE" 2>/dev/null; then
    echo "$TEMP_FILE"
else
    echo "Error: No image found in clipboard."
    rm -f "$TEMP_FILE"
    exit 1
fi
