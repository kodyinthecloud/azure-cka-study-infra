#!/bin/bash
 set -e
 export DEBIAN_FRONTEND=noninteractive

 # Pick the Kubernetes MINOR branch you want (for example 1.30 or 1.34).
 VERSION="1.30"

 # Init apt and prereqs
 sudo rm -rf /var/lib/apt/lists/* || true
 sudo mkdir -p /var/lib/apt/lists/partial
 sudo apt-get update -y
 sudo apt-get install -y ca-certificates curl gpg apt-transport-https

 # Install containerd (Ubuntu repo first, then fallback to Docker repo if missing)
 if ! sudo apt-get install -y containerd; then
   sudo install -m 0755 -d /etc/apt/keyrings
   curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
     | sudo gpg --batch --yes --dearmor -o /etc/apt/keyrings/docker.gpg
   echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
 https://download.docker.com/linux/ubuntu $(. /etc/os-release; echo $UBUNTU_CODENAME) stable" \
     | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
   sudo apt-get update -y
   sudo apt-get install -y containerd.io
 fi
 sudo systemctl enable --now containerd

 # Kubernetes apt repo
 sudo mkdir -p /etc/apt/keyrings
 curl -fsSL "https://pkgs.k8s.io/core:/stable:/v${VERSION}/deb/Release.key" \
   | sudo gpg --batch --yes --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
 sudo chmod 0644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg

 echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${VERSION}/deb/ /" \
   | sudo tee /etc/apt/sources.list.d/kubernetes.list >/dev/null
 sudo chmod 0644 /etc/apt/sources.list.d/kubernetes.list

 sudo apt-get update -y
 sudo apt-get install -y kubelet kubeadm kubectl
 sudo apt-mark hold kubelet kubeadm kubectl containerd containerd.io || true
