#! /bin/sh

sudo add-apt-repository ppa:noobslab/themes
sudo add-apt-repository ppa:noobslab/icons
sudo apt-get update
sudo apt-get install arc-theme arc-icons -y

sudo add-apt-repository ppa:varlesh-l/papirus-pack
sudo apt-get update
sudo apt-get install papirus-gtk-icon-theme -y