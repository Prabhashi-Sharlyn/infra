#!/bin/bash

set -e

echo "Getting all subnet IDs from the EKS cluster..."
ALL_SUBNETS=$(aws eks describe-cluster \
  --name betterwellness-cluster \
  --region ap-south-1 \
  --query "cluster.resourcesVpcConfig.subnetIds" \
  --output text)

echo "Reading Subnets..."
read -r -a SUBNET_ARRAY <<< "$ALL_SUBNETS"

echo "Extracting the Subnet IDs..."
FIRST_TWO_SUBNETS="${SUBNET_ARRAY[0]},${SUBNET_ARRAY[1]}"
echo "Using first two subnets: $FIRST_TWO_SUBNETS"

echo "Updating alb-ingress.yaml with Subnets..."
sed -i "s|alb.ingress.kubernetes.io/subnets: .*|alb.ingress.kubernetes.io/subnets: $FIRST_TWO_SUBNETS|" alb-ingress.yaml

echo "Applying ingress..."
kubectl apply -f alb-ingress.yaml

echo "Ingress configuration completed."
