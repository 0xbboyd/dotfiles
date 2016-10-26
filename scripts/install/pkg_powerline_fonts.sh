#! /bin/sh

# install powerline & powerline fonts
su -c 'pip install git+git://github.com/Lokaltog/powerline'

mkdir -p ~/src/tools && cd ~/src/tools
git clone https://github.com/powerline/fonts.git
fonts/install.sh

