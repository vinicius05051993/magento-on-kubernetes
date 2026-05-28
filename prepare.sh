#!/bin/bash

set -e

echo "Updating package lists..."

sudo apt update
sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y

echo "Installing base dependencies..."

sudo apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common \
    make \
    git \
    jq \
    unzip

echo "Disabling swap..."

sudo swapoff -a

sudo sed -i.bak '/ swap / s/^/#/' /etc/fstab

echo "Loading kernel modules..."

cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

echo "Configuring sysctl..."

cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
net.ipv4.ip_forward=1
EOF

sudo sysctl --system

echo "Creating keyrings directory..."

sudo mkdir -p /etc/apt/keyrings

echo "Adding Docker GPG key..."

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

sudo chmod a+r /etc/apt/keyrings/docker.gpg

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

echo "Enabling Docker..."

sudo systemctl enable docker
sudo systemctl start docker

echo "Adding current user to docker group..."

sudo usermod -aG docker $USER

echo "Installing kubectl..."

curl -LO "https://dl.k8s.io/release/$(curl -L -s \
https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

chmod +x kubectl

sudo mv kubectl /usr/local/bin/

echo "Installing kind..."

curl -Lo /tmp/kind \
https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64

chmod +x /tmp/kind

sudo mv /tmp/kind /usr/local/bin/kind

echo "Installing Helm..."

curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

echo ""
echo "Verifying installations..."
echo ""

sudo docker version
kubectl version --client
kind version
helm version
make --version
git --version
jq --version

echo ""
echo "Installation completed successfully."
echo ""
echo "IMPORTANT:"
echo "Log out and log in again before using Docker without sudo."
echo ""
echo "Or run:"
echo ""
echo "newgrp docker"