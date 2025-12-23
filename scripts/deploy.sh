#!/bin/bash

# Variables
ALB_ARN=$1
BLUE_TG_ARN=$2
GREEN_TG_ARN=$3
NEW_IMAGE=$4

# Determine current live target group
CURRENT_TG=$(aws elbv2 describe-listeners \
    --load-balancer-arn $ALB_ARN \
    --query "Listeners[0].DefaultActions[0].TargetGroupArn" \
    --output text)

# Determine idle target group
if [ "$CURRENT_TG" == "$BLUE_TG_ARN" ]; then
    IDLE_TG=$GREEN_TG_ARN
else
    IDLE_TG=$BLUE_TG_ARN
fi

echo "Current TG: $CURRENT_TG"
echo "Deploying new version to idle TG: $IDLE_TG"

# Update Docker container on idle target group instances
for INSTANCE in $(aws elbv2 describe-target-health \
    --target-group-arn $IDLE_TG \
    --query "TargetHealthDescriptions[*].Target.Id" \
    --output text); do

    echo "Updating instance $INSTANCE"
    aws ssm send-command \
        --targets "Key=instanceIds,Values=$INSTANCE" \
        --document-name "AWS-RunShellScript" \
        --comment "Deploying new Docker image" \
        --parameters 'commands=["docker stop blue-green-app || true","docker rm blue-green-app || true","docker run -d -p 8000:8000 '$NEW_IMAGE'"]'
done

# Wait for health check
echo "Waiting for health checks..."
sleep 60

# Switch ALB to new target group
aws elbv2 modify-listener \
    --listener-arn $(aws elbv2 describe-listeners --load-balancer-arn $ALB_ARN --query "Listeners[0].ListenerArn" --output text) \
    --default-actions Type=forward,TargetGroupArn=$IDLE_TG

echo "Traffic switched successfully to new version!"
