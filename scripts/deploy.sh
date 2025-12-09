#!/bin/bash
set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🚀 Starting AWS Deployment Pipeline${NC}"

# Variables
AWS_REGION=${AWS_REGION:-us-east-1}
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ENVIRONMENT=${ENVIRONMENT:-dev}
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo -e "${GREEN}✓ AWS Account: $AWS_ACCOUNT_ID${NC}"
echo -e "${GREEN}✓ Region: $AWS_REGION${NC}"
echo -e "${GREEN}✓ Environment: $ENVIRONMENT${NC}"

# Step 1: Deploy Infrastructure with Terraform
echo -e "\n${YELLOW}📦 Step 1: Deploying Infrastructure with Terraform${NC}"

cd infra

terraform init -backend-config="key=ai-devops-${ENVIRONMENT}.tfstate" \
               -backend-config="bucket=terraform-state-${AWS_ACCOUNT_ID}" \
               -backend-config="region=${AWS_REGION}" \
               -upgrade

terraform plan -var-file="environments/${ENVIRONMENT}.tfvars" -out=tfplan

echo -e "${YELLOW}Apply Terraform? (y/n)${NC}"
read -r apply_tf

if [ "$apply_tf" = "y" ]; then
  terraform apply tfplan
  echo -e "${GREEN}✓ Infrastructure deployed successfully${NC}"
else
  echo -e "${RED}✗ Terraform apply cancelled${NC}"
  exit 1
fi

# Get outputs
LAMBDA_ROLE_ARN=$(terraform output -raw lambda_role_arn)
ML_BUCKET=$(terraform output -raw ml_artifacts_bucket)
RAG_BUCKET=$(terraform output -raw rag_docs_bucket)
RAG_TABLE=$(terraform output -raw rag_table_name)

cd ..

# Step 2: Build and Deploy Lambda Functions
echo -e "\n${YELLOW}🔨 Step 2: Building and Deploying Lambda Functions${NC}"

# Deploy DevOps Assistant
echo -e "${YELLOW}Building devops-assistant Lambda...${NC}"
./scripts/build-lambda.sh devops_assistant $LAMBDA_ROLE_ARN $ENVIRONMENT

# Deploy RAG Service
echo -e "${YELLOW}Building rag-service Lambda...${NC}"
./scripts/build-lambda.sh rag_service $LAMBDA_ROLE_ARN $ENVIRONMENT

echo -e "${GREEN}✓ Lambda functions deployed${NC}"

# Step 3: Create API Gateway Endpoints
echo -e "\n${YELLOW}🌐 Step 3: Setting up API Gateway Endpoints${NC}"

DEVOPS_API_URL=$(./scripts/create-api-gateway.sh devops-assistant-${ENVIRONMENT} devops-assistant ${ENVIRONMENT})
RAG_API_URL=$(./scripts/create-api-gateway.sh rag-service-${ENVIRONMENT} rag-service ${ENVIRONMENT})

echo -e "${GREEN}✓ DevOps Assistant API: $DEVOPS_API_URL${NC}"
echo -e "${GREEN}✓ RAG Service API: $RAG_API_URL${NC}"

# Step 4: Store outputs in SSM Parameter Store for CI/CD access
echo -e "\n${YELLOW}💾 Step 4: Storing Configuration in Parameter Store${NC}"

aws ssm put-parameter \
  --name "/ai-devops/devops-assistant-api" \
  --value "$DEVOPS_API_URL" \
  --type "String" \
  --overwrite \
  --region "$AWS_REGION"

aws ssm put-parameter \
  --name "/ai-devops/rag-service-api" \
  --value "$RAG_API_URL" \
  --type "String" \
  --overwrite \
  --region "$AWS_REGION"

aws ssm put-parameter \
  --name "/ai-devops/ml-artifacts-bucket" \
  --value "$ML_BUCKET" \
  --type "String" \
  --overwrite \
  --region "$AWS_REGION"

echo -e "${GREEN}✓ Configuration stored in Parameter Store${NC}"

# Step 5: Run smoke tests
echo -e "\n${YELLOW}🧪 Step 5: Running Smoke Tests${NC}"

./scripts/smoke-tests.sh "$DEVOPS_API_URL" "$RAG_API_URL"

echo -e "\n${GREEN}✅ Deployment completed successfully!${NC}"
echo -e "${GREEN}Deployment Summary:${NC}"
echo -e "  DevOps Assistant API: $DEVOPS_API_URL"
echo -e "  RAG Service API: $RAG_API_URL"
echo -e "  ML Artifacts Bucket: $ML_BUCKET"
echo -e "  RAG Docs Bucket: $RAG_BUCKET"
echo -e "  DynamoDB Table: $RAG_TABLE"
