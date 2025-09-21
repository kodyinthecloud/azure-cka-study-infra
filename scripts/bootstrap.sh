#!/usr/bin/env bash
set -euo pipefail

# Install container runtime
apt-get update -y
apt-get install -y containerd

# Add Kubernetes apt repo
VERSION=1.30 # <-- change this to desired Kubernetes version branch
curl -fsSL https://pkgs.k8s.io/core:/stable:/v_${VERSION}/deb/Release.key \
  | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
https://pkgs.k8s.io/core:/stable:/v_${VERSION}/deb/ /" \
  | tee /etc/apt/sources.list.d/kubernetes.list

# Install kubelet, kubeadm, kubectl
apt-get update -y
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl containerd

echo "[bootstrap] Kubernetes prerequisites installed on $(hostname)"
