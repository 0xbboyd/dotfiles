#!/usr/bin/env sh

# Install apt-layer packages required by Omarchy-ported scripts and configs.
# These need system-level integration (sysfs, D-Bus, fontconfig) and can't
# be provided by nix or mise.
#
# Run after base_packages.sh. Safe to re-run (apt --no-install-recommends
# and --yes flags make it idempotent).
#
# See docs/omarchy-integration.md for the full dependency map.

sudo apt-get update

sudo apt-get install -y --no-install-recommends \
  tesseract-ocr \
  tesseract-ocr-eng \
  zbar-tools \
  ddcutil

echo "Omarchy apt dependencies installed."
echo ""
echo "  tesseract-ocr    — OCR text extraction (ocr-screenshot)"
echo "  zbar-tools       — QR code decoding (qr-screenshot)"
echo "  ddcutil          — external monitor brightness via DDC/CI"
echo ""
echo "Already installed (verified): foot, brightnessctl, upower, libglib2.0-bin, grim, slurp"
echo "swappy is installed via nix — see pkg_omarchy_nix.sh"
