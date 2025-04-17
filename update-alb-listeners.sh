#!/bin/bash

# Set variables
REGION="ap-south-1"
CLUSTER_NAME="betterwellness-cluster"
INGRESS_NAME="messaging-service-ingress"

# Get the ALB ARN
echo "Getting ALB from ingress $INGRESS_NAME..."
INGRESS_HOSTNAME=$(kubectl get ingress $INGRESS_NAME -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "Ingress hostname: $INGRESS_HOSTNAME"

ALB_ARN=$(aws elbv2 describe-load-balancers \
  --region $REGION \
  --query "LoadBalancers[?DNSName=='$INGRESS_HOSTNAME'].LoadBalancerArn" \
  --output text)
echo "ALB ARN: $ALB_ARN"

if [ -z "$ALB_ARN" ]; then
  echo "Error: Could not find ALB for ingress"
  exit 1
fi

# Get the HTTP listener
HTTP_LISTENER_ARN=$(aws elbv2 describe-listeners \
  --load-balancer-arn $ALB_ARN \
  --region $REGION \
  --query "Listeners[?Port==\`80\`].ListenerArn" \
  --output text)
echo "HTTP Listener ARN: $HTTP_LISTENER_ARN"

# Configure HTTP to HTTPS redirect
echo "Configuring HTTP to HTTPS redirect..."
aws elbv2 modify-listener \
  --listener-arn $HTTP_LISTENER_ARN \
  --region $REGION \
  --port 80 \
  --protocol HTTP \
  --default-actions Type=redirect,RedirectConfig="{Protocol=HTTPS,Port=443,StatusCode=HTTP_301}"
echo "HTTP to HTTPS redirect configured"

# Get the target group
TARGET_GROUP_ARN=$(aws elbv2 describe-target-groups \
  --region $REGION \
  --query "TargetGroups[?LoadBalancerArns[0]=='$ALB_ARN'].TargetGroupArn" \
  --output text)
echo "Target Group ARN: $TARGET_GROUP_ARN"

# Get the HTTPS listener
HTTPS_LISTENER_ARN=$(aws elbv2 describe-listeners \
  --load-balancer-arn $ALB_ARN \
  --region $REGION \
  --query "Listeners[?Port==\`443\`].ListenerArn" \
  --output text)
echo "HTTPS Listener ARN: $HTTPS_LISTENER_ARN"

# Configure HTTPS listener with recommended security policy
RECOMMENDED_POLICY="ELBSecurityPolicy-TLS13-1-2-2021-06"

if [ -n "$HTTPS_LISTENER_ARN" ]; then
  echo "Modifying HTTPS listener with recommended security policy..."
  aws elbv2 modify-listener \
    --listener-arn $HTTPS_LISTENER_ARN \
    --region $REGION \
    --ssl-policy $RECOMMENDED_POLICY \
    --default-actions Type=forward,TargetGroupArn=$TARGET_GROUP_ARN
  echo "HTTPS listener modified with recommended security policy"
else
  echo "HTTPS listener not found. You need an SSL certificate to create one."
  echo "To create an HTTPS listener, you need a certificate ARN from ACM."
  read -p "Do you have a certificate ARN? (y/n): " HAS_CERT
  if [[ "$HAS_CERT" =~ ^[Yy]$ ]]; then
    read -p "Enter your ACM Certificate ARN: " CERT_ARN
    aws elbv2 create-listener \
      --load-balancer-arn $ALB_ARN \
      --region $REGION \
      --protocol HTTPS \
      --port 443 \
      --ssl-policy $RECOMMENDED_POLICY \
      --certificates CertificateArn=$CERT_ARN \
      --default-actions Type=forward,TargetGroupArn=$TARGET_GROUP_ARN
    echo "Created new HTTPS listener with recommended security policy"
  else
    echo "To create an HTTPS listener, first create a certificate in ACM:"
    echo "aws acm request-certificate --domain-name yourdomain.com --validation-method DNS"
  fi
fi

echo "ALB configuration completed."