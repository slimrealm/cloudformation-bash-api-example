# This script deletes the CloudFormation stack if it exists.

# !/bin/bash

# Pull $STACK_NAME and $REGION from config-vars.sh
source ./config-vars.env

# Check if the stack exists
echo "🔍 Checking if stack '$STACK_NAME' exists..."
aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --region "$REGION" >/dev/null 2>&1

if [ $? -eq 0 ]; then
  echo "🧨 Stack '$STACK_NAME' exists. Deleting..."
  
  # Delete the stack
  aws cloudformation delete-stack \
    --stack-name "$STACK_NAME" \
    --region "$REGION"

  echo "⏳ Waiting for stack deletion to complete..."
  aws cloudformation wait stack-delete-complete \
    --stack-name "$STACK_NAME" \
    --region "$REGION"

  echo "✅ Stack '$STACK_NAME' deleted successfully."
else
  echo "✅ Stack '$STACK_NAME' does not exist. Nothing to delete."
fi
