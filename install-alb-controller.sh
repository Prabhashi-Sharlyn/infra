#!/bin/bash

echo "Downloading eksctl..."
curl --silent --location "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp

echo "Installing eksctl..."
sudo mv /tmp/eksctl /usr/local/bin

echo "Verifying eksctl installation..."
eksctl version

curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod +x get_helm.sh
./get_helm.sh

# Associate IAM OIDC provider for the EKS cluster
eksctl utils associate-iam-oidc-provider --cluster betterwellness-cluster --approve --region ap-south-1

# Download IAM Policy for LoadBalancer Controller
#curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json

# Create IAM policy for LoadBalancer controller
#aws iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy --policy-document file://iam_policy.json

# Create IAM service account for LoadBalancer controller
eksctl create iamserviceaccount --cluster betterwellness-cluster --namespace kube-system --name aws-load-balancer-controller --attach-policy-arn arn:aws:iam::147997140755:policy/AWSLoadBalancerControllerIAMPolicy --approve --region ap-south-1

# Add Helm repository for EKS charts and install the AWS Load Balancer Controller
helm repo add eks https://aws.github.io/eks-charts
helm repo update eks
helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system --set clusterName=betterwellness-cluster --set serviceAccount.create=false --set serviceAccount.name=aws-load-balancer-controller

# Apply CRDs for AWS Load Balancer Controller
kubectl apply -f https://raw.githubusercontent.com/aws/eks-charts/master/stable/aws-load-balancer-controller/crds/crds.yaml
