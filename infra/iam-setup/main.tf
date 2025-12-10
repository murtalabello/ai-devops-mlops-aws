terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ============================================================================
# Data source to get current AWS account ID
# ============================================================================
data "aws_caller_identity" "current" {}

# ============================================================================
# GitHub OIDC Provider (federated identity)
# ============================================================================
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]

  tags = {
    Name = "GitHub-OIDC-Provider"
  }
}

# ============================================================================
# GitHub Actions OIDC Role (for CI/CD deployments)
# ============================================================================
resource "aws_iam_role" "github_actions" {
  name = "GitHubActionsRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:*"
          }
        }
      }
    ]
  })

  tags = {
    Name = "GitHub-Actions-OIDC-Role"
  }
}

# ============================================================================
# Lambda Execution Role (for Lambda functions)
# ============================================================================
resource "aws_iam_role" "lambda_execution" {
  name = "ai-platform-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "Lambda-Execution-Role"
  }
}

# ============================================================================
# Attach policies to GitHub Actions Role
# ============================================================================

# S3 Full Access
resource "aws_iam_role_policy_attachment" "github_s3_full_access" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# DynamoDB Full Access
resource "aws_iam_role_policy_attachment" "github_dynamodb_full_access" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

# Lambda Full Access
resource "aws_iam_role_policy_attachment" "github_lambda_full_access" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AWSLambda_FullAccess"
}

# API Gateway Full Access
resource "aws_iam_role_policy_attachment" "github_apigateway_full_access" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/APIGatewayAdministrator"
}

# IAM Full Access (for creating/deleting roles)
resource "aws_iam_role_policy_attachment" "github_iam_full_access" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/IAMFullAccess"
}

# CloudFormation Full Access (used by SAM for Lambda deployment)
resource "aws_iam_role_policy_attachment" "github_cloudformation_full_access" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# ============================================================================
# Attach policies to Lambda Role
# ============================================================================

# S3 Full Access
resource "aws_iam_role_policy_attachment" "lambda_s3_full_access" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# DynamoDB Full Access
resource "aws_iam_role_policy_attachment" "lambda_dynamodb_full_access" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

# CloudWatch Logs
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

# ============================================================================
# Terraform Output - Role ARNs for GitHub Secrets
# ============================================================================
output "github_actions_role_arn" {
  description = "GitHub Actions OIDC Role ARN - Add to GitHub Secrets as AWS_ROLE_ARN"
  value       = aws_iam_role.github_actions.arn
}

output "lambda_execution_role_arn" {
  description = "Lambda Execution Role ARN - Add to GitHub Secrets as AWS_LAMBDA_ROLE_ARN"
  value       = aws_iam_role.lambda_execution.arn
}

output "aws_account_id" {
  description = "AWS Account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "github_secrets_config" {
  description = "GitHub Secrets configuration to add"
  value = {
    AWS_ROLE_ARN        = aws_iam_role.github_actions.arn
    AWS_LAMBDA_ROLE_ARN = aws_iam_role.lambda_execution.arn
    AWS_REGION          = var.aws_region
  }
}
