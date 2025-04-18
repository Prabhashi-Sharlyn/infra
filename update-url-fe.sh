#!/bin/bash

set -e

STAGE_NAME="prod"

API_URL=$(aws apigatewayv2 get-apis \
  --query "Items[?Name=='BetterWellnessAPI'].ApiEndpoint" \
  --output text)

aws amplify update-app \
  --app-id $(aws amplify list-apps --query 'apps[?name==`betterwellness-fe`].appId' --output text) \
  --environment-variables REACT_APP_GATEWAY_API_URL=$API_URL/$STAGE_NAME

aws amplify start-job \
  --app-id $(aws amplify list-apps --query 'apps[?name==`betterwellness-fe`].appId' --output text) \
  --branch-name automation \
  --job-type RELEASE
