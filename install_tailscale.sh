#!/bin/bash

echo "Installing Tailscale..."

# Add Tailscale's package signing key
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/noble.noarmor.gpg | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null

# Add Tailscale's repository
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/noble.tailscale-keyring.list | sudo tee /etc/apt/sources.list.d/tailscale.list

# Update package list
sudo apt-get update

# Install Tailscale
sudo apt-get install -y tailscale

echo "Tailscale installed successfully!"
echo "Run 'sudo tailscale up' to start and authenticate"