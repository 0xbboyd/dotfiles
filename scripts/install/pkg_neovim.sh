#!/usr/bin/env sh

# Install the latest Neovim (0.11+) via the unstable PPA for Ubuntu
sudo add-apt-repository -y ppa:neovim-ppa/unstable
sudo apt-get update
sudo apt-get install -y neovim
