#!/usr/bin/env sh

# Install NVM (Node Version Manager)
# Check latest version at https://github.com/nvm-sh/nvm/releases
NVM_VERSION="v0.40.1"

curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash

# Load nvm for the current session
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Install latest LTS version of Node.js
nvm install --lts
nvm use --lts

echo "NVM ${NVM_VERSION} and Node LTS installed."
