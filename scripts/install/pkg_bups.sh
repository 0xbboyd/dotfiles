#!/usr/bin/env sh

# install bup
sudo apt-get install bup 

# install bup GUI
# mkdir -p ~/src/tools && cd ~/src/tools
# git clone https://github.com/emersion/bups.git 
# cd bups
# python create-launcher.py

# create encrypted dropbox bup
mkdir -p ~/Dropbox/bup

encfs ~/Dropbox/bup ~/.bup