#!/bin/bash
set -e

# Pick the Kubernetes MINOR branch you want (for example 1.30 or 1.34).
VERSION="1.30"

# Install ContainerD
sudo apt-get install -y containerd

# Enable and start containerd
sudo systemctl enable --now containerd

# Make sure the keyrings directory exists.
sudo mkdir -p /etc/apt/keyrings

# Download the repo signing key and store it in the keyrings folder.
curl -fsSL "https://pkgs.k8s.io/core:/stable:/v${VERSION}/deb/Release.key" \
  | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Add the Kubernetes APT repository for the chosen minor branch.
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${VERSION}/deb/ /" \
  | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo chmod 644 /etc/apt/sources.list.d/kubernetes.list

# Refresh package lists so the new repo is recognized.
apt-get update -y

# Install the Kubernetes components.
apt-get install -y kubelet kubeadm kubectl

# Prevent unintended upgrades of these packages (and containerd if present).
apt-mark hold kubelet kubeadm kubectl containerd