#!/bin/bash
set -e

# Lambda build script
# Usage: ./build-lambda.sh <service_name> <lambda_role_arn> <environment>

SERVICE=$1
ROLE_ARN=$2
ENVIRONMENT=${3:-dev}
AWS_REGION=${AWS_REGION:-us-east-1}
FUNCTION_NAME="${SERVICE}-${ENVIRONMENT}"

if [ -z "$SERVICE" ] || [ -z "$ROLE_ARN" ]; then
  echo "Usage: $0 <service_name> <lambda_role_arn> [environment]"
  exit 1
fi

echo "🔨 Building Lambda: $FUNCTION_NAME"

cd "$SERVICE"

# Create package directory
mkdir -p package
cd package
rm -rf *

# Install dependencies
pip install -r ../requirements.txt -t . --quiet

# Copy Lambda handler
cp ../lambda_function.py .

# Create deployment package
zip -r ../${SERVICE}_${ENVIRONMENT}_$(date +%s).zip . > /dev/null

# Get latest zip file
LATEST_ZIP=$(ls -t ../${SERVICE}_${ENVIRONMENT}_*.zip | head -1)

echo "📦 Package created: $LATEST_ZIP"

cd ..

# Check if function exists
FUNCTION_EXISTS=$(aws lambda list-functions --region "$AWS_REGION" --query "Functions[?FunctionName=='$FUNCTION_NAME'].FunctionName" --output text)

if [ -z "$FUNCTION_EXISTS" ]; then
  echo "Creating Lambda function: $FUNCTION_NAME"
  
  # Get environment variables from .env or defaults
  ENV_VARS="{OPENAI_API_KEY=${OPENAI_API_KEY},ENVIRONMENT=${ENVIRONMENT}}"
  
  if [ "$SERVICE" = "rag_service" ]; then
    ENV_VARS="${ENV_VARS},RAG_TABLE=/ai-devops/rag-table,RAG_BUCKET=/ai-devops/rag-bucket"
  fi
  
  aws lambda create-function \
    --function-name "$FUNCTION_NAME" \
    --runtime python3.11 \
    --role "$ROLE_ARN" \
    --handler lambda_function.lambda_handler \
    --zip-file "fileb://$LATEST_ZIP" \
    --environment "Variables=$ENV_VARS" \
    --timeout 60 \
    --memory-size 256 \
    --region "$AWS_REGION" \
    > /dev/null
    
  echo "✅ Lambda function created"
else
  echo "Updating Lambda function: $FUNCTION_NAME"
  
  aws lambda update-function-code \
    --function-name "$FUNCTION_NAME" \
    --zip-file "fileb://$LATEST_ZIP" \
    --region "$AWS_REGION" \
    > /dev/null
    
  echo "✅ Lambda function updated"
fi

# Cleanup
rm -rf package
rm -f ${SERVICE}_${ENVIRONMENT}_*.zip

cd ..
echo "✓ Lambda deployment complete: $FUNCTION_NAME"
