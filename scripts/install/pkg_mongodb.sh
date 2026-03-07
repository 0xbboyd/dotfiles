#!/usr/bin/env sh

# MongoDB 8.0 Installation for Ubuntu 24.04 (Noble)
sudo apt-get install -y gnupg curl

# Import the public GPG key for the latest MongoDB version
curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | \
   sudo gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg \
   --dearmor

# Create a list file for MongoDB
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu noble/mongodb-org/8.0 multiverse" | \
  sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list

# Update local package database
sudo apt-get update

# Install the MongoDB packages
sudo apt-get install -y mongodb-org

# Start and enable the service
sudo systemctl enable --now mongod
sudo systemctl status mongod --no-pager
