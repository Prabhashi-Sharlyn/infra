#!/bin/bash

echo "Downloading eksctl..."
curl --silent --location "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp

echo "Installing eksctl..."
sudo mv /tmp/eksctl /usr/local/bin

echo "Verifying eksctl installation..."
eksctl version

echo "Creating EKS cluster using your-config.yaml..."
eksctl create cluster -f eks-cluster.yaml
