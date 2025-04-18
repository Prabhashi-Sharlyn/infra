#!/bin/bash

set -e

echo "Fetching Amplify App Domain..."
APP_ID=$(aws amplify list-apps --query 'apps[?name==`betterwellness-fe`].appId' --output text)
FE_DOMAIN=$(aws amplify get-app --app-id $APP_ID --query 'app.defaultDomain' --output text)
BRANCH="automation"
FE_URL="https://$BRANCH.$FE_DOMAIN"
echo "Frontend available at: $FE_URL"

echo "Creating API Gateway..."
aws cloudformation create-stack \
  --stack-name betterwellness-api-gateway \
  --template-body file://api-gateway-stack.yaml \
  --parameters \
    ParameterKey=AmplifyFrontendURL,ParameterValue=$FE_URL \
    ParameterKey=UserServiceELB,ParameterValue=$(kubectl get svc user-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}') \
    ParameterKey=BookingServiceELB,ParameterValue=$(kubectl get svc booking-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}') \
  --capabilities CAPABILITY_NAMED_IAM

echo "Gateway Creation Completed."