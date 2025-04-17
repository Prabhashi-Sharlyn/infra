#!/bin/bash

# Get all subnet IDs from the EKS cluster
ALL_SUBNETS=$(aws eks describe-cluster \
  --name betterwellness-cluster \
  --region ap-south-1 \
  --query "cluster.resourcesVpcConfig.subnetIds" \
  --output text)

# Convert to array
read -r -a SUBNET_ARRAY <<< "$ALL_SUBNETS"

# Extract the first two subnet IDs
FIRST_TWO_SUBNETS="${SUBNET_ARRAY[0]},${SUBNET_ARRAY[1]}"
echo "Using first two subnets: $FIRST_TWO_SUBNETS"

# Update the ingress YAML with only the first two subnets
echo "Updating alb-ingress.yaml with first two subnets..."
sed -i "s|alb.ingress.kubernetes.io/subnets: .*|alb.ingress.kubernetes.io/subnets: $FIRST_TWO_SUBNETS|" alb-ingress.yaml

# Apply the ingress configuration
echo "Applying ingress..."
kubectl apply -f alb-ingress.yaml

echo "✅ Ingress configuration completed."
