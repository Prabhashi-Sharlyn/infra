#!/bin/bash

set -e

echo "Deploying ECR Repositories..."
aws cloudformation create-stack --stack-name BetterWellnessECR --template-body file://ecr.yaml

echo "Running EKS setup and Cluster Deployment..."
chmod +x setup-eksctl.sh
./setup-eksctl.sh

echo "Deploying Frontend..."
TOKEN=$(aws secretsmanager get-secret-value --secret-id github-oauth-token --query SecretString --output text)
aws cloudformation deploy \
--template-file amplify.yaml \
--stack-name amplify-fe-stack \
--capabilities CAPABILITY_IAM \
--parameter-overrides GitHubAccessToken=$TOKEN

echo "Cluster Deployment & Frontend Deployment Done..."