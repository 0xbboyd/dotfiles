#!/usr/bin/env sh

# install bup
sudo apt-get install bup

# dependencis for gnome-encfs
sudo apt-get install mercurial
sudo apt-get install python-gnomekeyring

cd ~/src
hg clone http://bitbucket.org/obensonne/gnome-encfs
cd gnome-encfs
install gnome-encfs /usr/local/bin

# create encrypted dropbox bup
mkdir -p ~/Dropbox/bup

# encfs ~/Dropbox/bup ~/.bup
gnome-encfs -a ~/Dropbox/bup ~/.bup
