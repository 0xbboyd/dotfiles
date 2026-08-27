#!/usr/bin/env sh

# Install nix-layer packages required by Omarchy-ported configs.
# These are CLI/dev tools that move faster than Debian stable.
#
# Requires nix: sh <(curl -L https://nixos.org/nix/install) --daemon
# See docs/package-manager-layering.md for the ownership matrix.

nix profile install nixpkgs#starship nixpkgs#swappy

echo "Omarchy nix dependencies installed."
echo ""
echo "  starship         — minimal prompt (config/starship.toml)"
echo "  swappy           — screenshot annotation editor (not in Ubuntu apt repos)"
