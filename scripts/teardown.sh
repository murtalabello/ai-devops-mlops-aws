#!/bin/bash
set -e

# Teardown script - destroys all AWS resources
# Usage: ./teardown.sh [environment]

ENVIRONMENT=${1:-dev}
AWS_REGION=${AWS_REGION:-us-east-1}

echo "⚠️  WARNING: This will destroy all AI DevOps MLOps AWS infrastructure in $ENVIRONMENT environment"
echo "Press Ctrl+C to cancel, or Enter to continue..."
read -r

# Delete API Gateways
echo "🗑️  Deleting API Gateways..."
aws apigateway get-rest-apis --region "$AWS_REGION" \
  --query "items[?contains(name, '$ENVIRONMENT')].id" \
  --output text | xargs -I {} \
  aws apigateway delete-rest-api --rest-api-id {} --region "$AWS_REGION" 2>/dev/null || true

# Delete Lambda Functions
echo "🗑️  Deleting Lambda Functions..."
aws lambda list-functions --region "$AWS_REGION" \
  --query "Functions[?contains(FunctionName, '$ENVIRONMENT')].FunctionName" \
  --output text | xargs -I {} \
  aws lambda delete-function --function-name {} --region "$AWS_REGION" 2>/dev/null || true

# Delete IAM Roles
echo "🗑️  Deleting IAM Roles..."
aws iam list-roles --query "Roles[?contains(RoleName, 'ai-devops')].RoleName" \
  --output text | xargs -I {} \
  aws iam delete-role --role-name {} 2>/dev/null || true

# Destroy Terraform infrastructure
echo "🗑️  Destroying Terraform infrastructure..."
cd infra
terraform destroy -auto-approve -var-file="environments/${ENVIRONMENT}.tfvars" || true
cd ..

echo "✅ Teardown complete!"
