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
  region = var.region
}

# ============================================================================
# NOTE: Before running this, create IAM roles by running:
# cd infra/iam-setup && terraform init && terraform apply -auto-approve
# This creates GitHub Actions OIDC role and Lambda execution role
# ============================================================================

# S3 bucket for ML artifacts & RAG docs
resource "aws_s3_bucket" "ml_artifacts" {
  bucket = var.ml_artifacts_bucket
}

resource "aws_s3_bucket" "rag_docs" {
  bucket = var.rag_docs_bucket
}

# DynamoDB for RAG chunks
resource "aws_dynamodb_table" "rag_table" {
  name         = var.rag_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "doc_id"
  range_key    = "chunk_id"

  attribute {
    name = "doc_id"
    type = "S"
  }

  attribute {
    name = "chunk_id"
    type = "S"
  }
}

# IAM role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "ai_platform_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_s3_dynamo" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_dynamo" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

# Package & deploy lambda (you might build zip via CI and point to S3)
resource "aws_lambda_function" "devops_assistant" {
  function_name = "devops-assistant"
  role          = aws_iam_role.lambda_role.arn
  runtime       = "python3.11"
  handler       = "lambda_function.lambda_handler"
  filename      = var.devops_assistant_package  # path to zip
  timeout       = 30

  environment {
    variables = {
      OPENAI_API_KEY = var.openai_api_key
    }
  }
}

resource "aws_apigatewayv2_api" "devops_api" {
  name          = "devops-assistant-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "devops_integration" {
  api_id           = aws_apigatewayv2_api.devops_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.devops_assistant.arn
  integration_method = "POST"
}

resource "aws_lambda_permission" "apigw_invoke_devops" {
  statement_id  = "AllowAPIGatewayInvokeDevops"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.devops_assistant.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.devops_api.execution_arn}/*/*"
}

resource "aws_apigatewayv2_route" "devops_route" {
  api_id    = aws_apigatewayv2_api.devops_api.id
  route_key = "POST /analyze"
  target    = "integrations/${aws_apigatewayv2_integration.devops_integration.id}"
}

resource "aws_apigatewayv2_stage" "devops_stage" {
  api_id      = aws_apigatewayv2_api.devops_api.id
  name        = "$default"
  auto_deploy = true
}

output "devops_assistant_url" {
  value = aws_apigatewayv2_api.devops_api.api_endpoint
}
