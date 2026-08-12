#!/usr/bin/env bash
# Installs Docker Engine + Docker Compose plugin on Ubuntu (EC2), adds the
# ubuntu user to the docker group, and confirms sudo access.
# Run this ON the EC2 instance after SSH-ing in: bash setup-docker.sh
set -euo pipefail

echo "=== Updating system packages ==="
sudo apt-get update -y
sudo apt-get upgrade -y

echo "=== Installing prerequisites ==="
sudo apt-get install -y ca-certificates curl gnupg lsb-release

echo "=== Adding Docker's official GPG key ==="
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo "=== Adding Docker's apt repository ==="
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -y

echo "=== Installing Docker Engine, CLI, containerd, Buildx, and Compose plugin ==="
sudo apt-get install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin

echo "=== Enabling and starting the Docker service ==="
sudo systemctl enable docker
sudo systemctl start docker

echo "=== Adding 'ubuntu' user to the docker group (run docker without sudo) ==="
sudo usermod -aG docker ubuntu

echo "=== Ensuring 'ubuntu' user has sudo privileges ==="
# On stock Ubuntu EC2 AMIs, 'ubuntu' is already in the sudo group by default.
# This is just a safety net in case that's ever not true.
sudo usermod -aG sudo ubuntu

echo ""
echo "=== Verifying installation ==="
docker --version
docker compose version

echo ""
echo "======================================================"
echo "Docker Engine + Compose installed successfully."
echo ""
echo "IMPORTANT: group membership changes require a fresh"
echo "login session to take effect. Either:"
echo "  1. Log out and SSH back in, OR"
echo "  2. Run: newgrp docker"
echo "before trying 'docker ps' without sudo."
echo "======================================================"
