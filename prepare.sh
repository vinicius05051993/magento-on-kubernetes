#!/bin/bash

set -e

echo "Updating package lists..."
sudo apt update
sudo apt upgrade -y

echo "Installing required dependencies..."
sudo apt install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    make

echo "Creating keyrings directory..."
sudo mkdir -p /etc/apt/keyrings

echo "Adding Docker GPG key..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo "Adding Docker repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) \
  signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update

echo "Installing Docker..."
sudo apt install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin

echo "Adding current user to docker group..."
sudo usermod -aG docker $USER

echo "Installing kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s \
https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

chmod +x kubectl
sudo mv kubectl /usr/local/bin/

echo "Installing kind..."
curl -Lo ./kind \
https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64

chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

echo "Installing Helm..."
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

echo ""
echo "Verifying installations..."
echo ""

docker version
kubectl version --client
kind version
helm version
make --version

echo ""
echo "Installation completed successfully."
echo "Run the command below to apply the docker group without rebooting:"
echo ""
echo "newgrp docker"