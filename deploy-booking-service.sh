#!/bin/bash

set -e

echo "Obtaining OAuth Token..."
TOKEN=$(aws secretsmanager get-secret-value --secret-id github-oauth-token --query SecretString --output text)

echo "Fetching Amplify App Domain..."
APP_ID=$(aws amplify list-apps --query 'apps[?name==`betterwellness-fe`].appId' --output text)
FE_DOMAIN=$(aws amplify get-app --app-id $APP_ID --query 'app.defaultDomain' --output text)
BRANCH="automation"
FE_URL="https://$BRANCH.$FE_DOMAIN"
echo "Frontend available at: $FE_URL"

echo "Booking Service Pipeline CI/CD..."
aws cloudformation deploy \
  --template-file codepipeline-booking-service.yaml \
  --stack-name booking-service-pipeline-stack \
  --parameter-overrides \
    GitHubRepoUrl=https://github.com/Prabhashi-Sharlyn/booking-service \
    BranchName=automation \
    CodeBuildServiceRoleArn=arn:aws:iam::147997140755:role/betterwellness-user-codebuild-role \
    CodePipelineServiceRoleArn=arn:aws:iam::147997140755:role/CodePipelineServiceRole \
    FrontendURL=$FE_URL \
    GitHubOAuthToken=$TOKEN \
    --capabilities CAPABILITY_NAMED_IAM

echo "CodeBuild and CodePipeline Deployment Done..."

