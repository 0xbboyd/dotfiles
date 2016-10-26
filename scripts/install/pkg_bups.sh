#!/usr/bin/env sh

# GDrive FUSE fs
sudo add-apt-repository ppa:alessandro-strada/ppa
sudo apt-get update
sudo apt-get install google-drive-ocamlfuse

# BUPS
mkdir -p ~/src/tools && cd ~/src/tools
git clone https://github.com/emersion/bups.git 
cd bups
python create-launcher.py