#!/bin/bash

sudo rm -fr /opt/franz
sudo rm -fr /usr/share/applications/franz.desktop

# create installation dir
sudo mkdir -p /opt/franz

# Install Franz (Update to 5.10.0)
FRANZ_VERSION="5.10.0"
wget -q "https://github.com/meetfranz/franz/releases/download/v${FRANZ_VERSION}/franz_${FRANZ_VERSION}_amd64.deb" -O /tmp/franz.deb
sudo apt-get install -y /tmp/franz.deb
rm /tmp/franz.deb

echo "Franz ${FRANZ_VERSION} installed successfully."
