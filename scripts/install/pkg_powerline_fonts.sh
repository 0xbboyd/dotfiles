#!/usr/bin/env sh

# install powerline & powerline fonts
# Powerline utility (Python)
sudo apt-get install -y python3-powerline

# Powerline fonts repository
mkdir -p ~/src/tools && cd ~/src/tools
if [ ! -d "fonts" ]; then
    git clone https://github.com/powerline/fonts.git
fi
cd fonts
./install.sh

echo "Powerline fonts installed."
