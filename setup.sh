#!/bin/bash

# ============================================================================
# AI DevOps MLOps AWS - Automated Setup Script
# ============================================================================
# This script automates the IAM role creation via Terraform
# Run this once before deploying services via GitHub Actions
# ============================================================================

set -e  # Exit on error

echo "🚀 AI DevOps MLOps AWS - Automated Setup"
echo "=========================================="
echo ""

# Check prerequisites
echo "📋 Checking prerequisites..."

if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform not found. Please install Terraform first:"
    echo "   https://www.terraform.io/downloads.html"
    exit 1
fi

if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI not found. Please install AWS CLI first:"
    echo "   https://aws.amazon.com/cli/"
    exit 1
fi

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "")
if [ -z "$AWS_ACCOUNT_ID" ]; then
    echo "❌ AWS credentials not configured. Run 'aws configure' first"
    exit 1
fi

echo "✅ All prerequisites found"
echo ""

# Get GitHub credentials
echo "📝 GitHub Configuration"
read -p "Enter GitHub organization/username (default: murtalabello): " GITHUB_ORG
GITHUB_ORG=${GITHUB_ORG:-murtalabello}

read -p "Enter GitHub repository name (default: ai-devops-mlops-aws): " GITHUB_REPO
GITHUB_REPO=${GITHUB_REPO:-ai-devops-mlops-aws}

echo ""
echo "🔐 AWS Configuration"
read -p "Enter AWS region (default: us-east-1): " AWS_REGION
AWS_REGION=${AWS_REGION:-us-east-1}

echo ""
echo "=========================================="
echo "Configuration Summary:"
echo "  AWS Account ID: $AWS_ACCOUNT_ID"
echo "  AWS Region: $AWS_REGION"
echo "  GitHub Org: $GITHUB_ORG"
echo "  GitHub Repo: $GITHUB_REPO"
echo "=========================================="
echo ""

# Navigate to IAM setup directory
cd "$(dirname "$0")/infra/iam-setup" || exit 1

echo "🔧 Setting up IAM roles via Terraform..."
echo ""

# Initialize Terraform
echo "📦 Initializing Terraform..."
terraform init -no-color

# Plan (for review)
echo "📋 Planning Terraform changes..."
terraform plan -no-color \
  -var="aws_region=$AWS_REGION" \
  -var="github_org=$GITHUB_ORG" \
  -var="github_repo=$GITHUB_REPO" \
  -out=tfplan

echo ""
echo "=========================================="
echo "Review the plan above. Proceed? (yes/no)"
read -p "> " PROCEED

if [ "$PROCEED" != "yes" ]; then
    echo "Cancelled. Run this script again to retry."
    rm tfplan
    exit 0
fi

# Apply
echo ""
echo "🚀 Applying Terraform configuration..."
terraform apply -no-color tfplan
rm tfplan

echo ""
echo "=========================================="
echo "✅ IAM Roles Created Successfully!"
echo "=========================================="
echo ""

# Get outputs
echo "📤 Retrieving role ARNs..."
GITHUB_ROLE_ARN=$(terraform output -raw github_actions_role_arn)
LAMBDA_ROLE_ARN=$(terraform output -raw lambda_execution_role_arn)

echo ""
echo "=========================================="
echo "🔐 Add these to GitHub Secrets:"
echo "=========================================="
echo ""
echo "1. Go to: https://github.com/$GITHUB_ORG/$GITHUB_REPO/settings/secrets/actions"
echo ""
echo "2. Add these secrets:"
echo ""
echo "   Name: AWS_ROLE_ARN"
echo "   Value: $GITHUB_ROLE_ARN"
echo ""
echo "   Name: AWS_LAMBDA_ROLE_ARN"
echo "   Value: $LAMBDA_ROLE_ARN"
echo ""
echo "   Name: AWS_REGION"
echo "   Value: $AWS_REGION"
echo ""
echo "   Name: OPENAI_API_KEY"
echo "   Value: sk-... (from https://platform.openai.com/api-keys)"
echo ""
echo "=========================================="
echo ""
echo "✨ Next Steps:"
echo "   1. ✅ Added GitHub Secrets (above)"
echo "   2. 🚀 Go to GitHub Actions and run: Deploy Infrastructure"
echo "   3. 🚀 Then run: Deploy DevOps Assistant"
echo "   4. 🚀 Then run: Deploy RAG Service"
echo "   5. 🚀 Then run: MLOps - Train & Deploy Model"
echo ""
echo "See START_HERE.md for complete documentation"
echo ""
