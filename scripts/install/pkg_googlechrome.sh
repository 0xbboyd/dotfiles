#!/usr/bin/env sh

# Install Google Chrome stable via official repository
sudo apt-get install -y wget curl gnupg

# Add Google's signing key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor -o /etc/apt/keyrings/google-chrome.gpg

# Set up the stable repository
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list

# Update package index and install Chrome
sudo apt-get update
sudo apt-get install -y google-chrome-stable
