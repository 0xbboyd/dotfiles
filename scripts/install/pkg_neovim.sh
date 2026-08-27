#!/usr/bin/env sh

# Install Neovim via nix (replaces the old apt+unstable PPA approach)
# Requires nix to be installed: sh <(curl -L https://nixos.org/nix/install) --daemon
nix profile install nixpkgs#neovim
