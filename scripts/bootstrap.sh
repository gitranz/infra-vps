#!/bin/bash
set -e

# Update and install dependencies
sudo apt update -y
sudo apt upgrade -y
sudo apt install -y ca-certificates curl gnupg lsb-release

# Add Docker’s official GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up the stable repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update -y

# Install Docker Engine
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add current user to the docker group
sudo usermod -aG docker "$USER"

# Configure UFW
sudo ufw allow OpenSSH
sudo ufw allow "Nginx Full" # Assuming Nginx will handle web traffic
sudo ufw --force enable # Use --force to avoid interactive prompt

# Create /srv directory structure for persistent data
sudo mkdir -p /srv/n8n/data
sudo mkdir -p /srv/ollama/data
sudo mkdir -p /srv/openwebui/data
sudo mkdir -p /srv/nginx/data
sudo mkdir -p /srv/nginx/letsencrypt
sudo mkdir -p /srv/vscode/config

echo "Docker, UFW, and /srv directories setup complete. Please log out and back in for Docker group changes to take effect."
