#!/usr/bin/env sh

# install wezterm from official repo

# 1. Add GPG Key
curl -fsSL https://apt.fury.io/wez/gpg.key | sudo gpg --yes --dearmor -o /usr/share/keyrings/wezterm-fury.gpg

# 2. Add Repository
echo 'deb [signed-by=/usr/share/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' | sudo tee /etc/apt/sources.list.d/wezterm.list

# 3. Update and Install
sudo apt update
sudo apt install -y wezterm

echo "WezTerm installed successfully."
