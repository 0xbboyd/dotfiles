#!/usr/bin/env sh

# Base system packages — apt layer only
# Dev tooling (neovim, eza, delta, ripgrep, jq, tmux, etc.) is managed by nix.
# Runtimes and agent harnesses (node, python, go, etc.) are managed by mise.
# See docs/package-manager-layering.md for the full ownership matrix.
#
# NOTE: Some packages listed here (xclip, wl-clipboard, tree, jq, htop, tig,
# tmux) are also installed via nix in the normal setup. They remain listed
# because apt may pull them as dependencies of other packages (e.g. pass
# requires tree, xclip, wl-clipboard). The nix versions take precedence
# via PATH ordering. When running a fresh install, run pkg_neovim.sh and
# the nix profile install command from the layering doc AFTER this script.

sudo apt-get update
sudo apt-get install -y xclip \
                        wl-clipboard \
                        tree \
                        git \
                        zsh \
                        dconf-editor \
                        tmux \
                        gnupg \
                        jq \
                        ppa-purge \
                        network-manager-openvpn \
                        network-manager-openvpn-gnome \
                        htop \
                        python3-pip \
                        tig \
                        foot \
                        brightnessctl \
                        upower \
                        libglib2.0-bin \
                        grim \
                        slurp \
                        tesseract-ocr \
                        tesseract-ocr-eng \
                        zbar-tools \
                        ddcutil
