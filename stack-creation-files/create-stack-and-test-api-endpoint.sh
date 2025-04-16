# This script creates a CloudFormation stack that includes a DynamoDB table, an IAM role,
# a Lambda function, and an API Gateway.  Then adds test item to table, deploys the API,
# and tests the API endpoint with a GET request using curl.

#!/bin/bash

# Pull $STACK_NAME and $REGION from config-vars.sh
source ./config-vars.env

S3_TEMPLATE_URL="https://${BUCKET_NAME}.s3.${REGION}.amazonaws.com/stack-creation-files/dynamo-lambda-api-cf-stack.yaml"
CAPABILITIES="CAPABILITY_NAMED_IAM"

# Start from clean slate.  Delete this CloudFormation stack if it already exists.
source ./delete-stack.sh

# Create stack with DynamoDB table, IAM role, Lambda function, and API Gateway
aws cloudformation create-stack \
--stack-name $STACK_NAME \
--template-url $S3_TEMPLATE_URL \
--parameters ParameterKey=S3BucketName,ParameterValue=$BUCKET_NAME \
--region $REGION \
--capabilities $CAPABILITIES

# Wait for stack creation to complete
echo "⏳ Waiting for stack to finish creating..."
if aws cloudformation wait stack-create-complete --stack-name "$STACK_NAME"; then
  echo "✅ Stack created successfully"
else
  echo "❌ Stack creation failed"
  # Describe the failure
  aws cloudformation describe-stack-events --stack-name "$STACK_NAME" \
    --query "StackEvents[?ResourceStatus=='CREATE_FAILED'].[LogicalResourceId,ResourceStatusReason]" \
    --output table
  exit 1
fi

# Add test item to DynamoDB table
echo "Adding test item to DynamoDB table..."
aws dynamodb put-item \
--table-name Projects \
--item '{
"userId": {"S": "superman"},
"projectId": {"S": "save-the-day"},
"strategy": {"S": "speed"}
}'
if [ $? -eq 0 ]; then
  echo "✅ Test item added to DynamoDB table"
else
  echo "❌ Failed to add test item to DynamoDB table"
  exit 1
fi

# Get API Gateway API ID and Deploy API
echo "⏳ Getting API Gateway API ID and deploying API..."
API_ID=$(aws apigateway get-rest-apis \
 --region $REGION \
 --query "items[?name=='ProjectsAPI'].id" \
 --output text)

if [ $? -ne 0 ] || [ -z "$API_ID" ]; then
  echo "❌ Failed to retrieve API Gateway ID. Make sure the API named 'ProjectsAPI' exists and region is correct."
  exit 1
fi

aws apigateway create-deployment \
 --rest-api-id $API_ID \
 --stage-name prod \
 --description "Initial deployment for prod stage"

if [ $? -eq 0 ]; then
  echo "✅ API Gateway API deployed successfully"
else
  echo "❌ Failed to deploy API Gateway API"
  exit 1
fi

# Get API Gateway endpoint URL
INVOKE_URL_GET_ENDPOINT="https://${API_ID}.execute-api.${REGION}.amazonaws.com/prod/projects"

# Test API Gateway endpoint with GET request using curl
GET_REQUEST_WITH_PARAM="$INVOKE_URL_GET_ENDPOINT?userId=superman"
echo "Endpoint URL: $INVOKE_URL_GET_ENDPOINT"
echo "Testing GET endpoint with 'curl $GET_REQUEST_WITH_PARAM' ..."
EXPECTED_JSON='[{"projectId":"save-the-day","strategy":"speed","userId":"superman"}]'
RESPONSE=$(curl -s "$GET_REQUEST_WITH_PARAM")
echo "Response: $RESPONSE"

EXPECTED_SORTED=$(echo "$EXPECTED_JSON" | jq -S .)
RESPONSE_SORTED=$(echo "$RESPONSE" | jq -S .)

echo "Expected: $EXPECTED_SORTED"
echo "Actual: $RESPONSE_SORTED"

if [ "$RESPONSE_SORTED" = "$EXPECTED_SORTED" ]; then
echo "✅ API response content is correct!"
else
echo "❌ API response does not match expected"
exit 1
fi
