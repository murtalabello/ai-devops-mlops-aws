#!/bin/bash
set -e

# Create or update API Gateway with Lambda integration
# Usage: ./create-api-gateway.sh <api_name> <lambda_function> <environment>

API_NAME=$1
LAMBDA_FUNCTION=$2
ENVIRONMENT=${3:-dev}
AWS_REGION=${AWS_REGION:-us-east-1}

if [ -z "$API_NAME" ] || [ -z "$LAMBDA_FUNCTION" ]; then
  echo "Usage: $0 <api_name> <lambda_function> [environment]"
  exit 1
fi

echo "🌐 Setting up API Gateway: $API_NAME"

LAMBDA_ARN="arn:aws:lambda:${AWS_REGION}:$(aws sts get-caller-identity --query Account --output text):function:${LAMBDA_FUNCTION}-${ENVIRONMENT}"

# Check if API exists
API_ID=$(aws apigateway get-rest-apis --region "$AWS_REGION" \
  --query "items[?name=='$API_NAME'].id" --output text)

if [ -z "$API_ID" ]; then
  echo "Creating REST API: $API_NAME"
  
  API_ID=$(aws apigateway create-rest-api \
    --name "$API_NAME" \
    --description "API for $LAMBDA_FUNCTION" \
    --region "$AWS_REGION" \
    --query 'id' \
    --output text)
    
  echo "✅ REST API created: $API_ID"
else
  echo "✓ REST API already exists: $API_ID"
fi

# Get root resource
ROOT_ID=$(aws apigateway get-resources \
  --rest-api-id "$API_ID" \
  --region "$AWS_REGION" \
  --query 'items[0].id' \
  --output text)

# Create POST method
echo "Creating POST method..."

aws apigateway put-method \
  --rest-api-id "$API_ID" \
  --resource-id "$ROOT_ID" \
  --http-method POST \
  --authorization-type NONE \
  --region "$AWS_REGION" \
  2>/dev/null || echo "Method already exists"

# Create Lambda integration
echo "Setting up Lambda integration..."

aws apigateway put-integration \
  --rest-api-id "$API_ID" \
  --resource-id "$ROOT_ID" \
  --http-method POST \
  --type AWS_PROXY \
  --integration-http-method POST \
  --uri "arn:aws:apigateway:${AWS_REGION}:lambda:path/2015-03-31/functions/${LAMBDA_ARN}/invocations" \
  --region "$AWS_REGION" \
  2>/dev/null || echo "Integration already exists"

# Add Lambda permission
aws lambda add-permission \
  --function-name "${LAMBDA_FUNCTION}-${ENVIRONMENT}" \
  --statement-id "apigateway-access-$(date +%s)" \
  --action lambda:InvokeFunction \
  --principal apigateway.amazonaws.com \
  --source-arn "arn:aws:execute-api:${AWS_REGION}:$(aws sts get-caller-identity --query Account --output text):${API_ID}/*/*" \
  --region "$AWS_REGION" \
  2>/dev/null || echo "Permission already exists"

# Deploy API
echo "Deploying API Gateway..."

DEPLOYMENT_ID=$(aws apigateway create-deployment \
  --rest-api-id "$API_ID" \
  --stage-name "$ENVIRONMENT" \
  --region "$AWS_REGION" \
  --query 'id' \
  --output text)

echo "✅ Deployment created: $DEPLOYMENT_ID"

# Get API URL
API_URL="https://${API_ID}.execute-api.${AWS_REGION}.amazonaws.com/${ENVIRONMENT}/"

echo "✅ API Gateway setup complete"
echo "$API_URL"
