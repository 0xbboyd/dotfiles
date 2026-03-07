#!/usr/bin/env sh

# Install Spotify via official repository
sudo apt-get install -y curl gnupg

# Add Spotify's signing key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.spotify.com/debian/pubkey_6224F994118D76A3.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/spotify.gpg

# Set up the stable repository
echo "deb [signed-by=/etc/apt/keyrings/spotify.gpg] http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list

# Update package index and install Spotify
sudo apt-get update
sudo apt-get install -y spotify-client
