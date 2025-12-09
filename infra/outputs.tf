output "region" {
  description = "AWS region deployed to"
  value       = var.region
}

output "ml_artifacts_bucket" {
  description = "S3 bucket for ML artifacts"
  value       = aws_s3_bucket.ml_artifacts.id
}

output "rag_docs_bucket" {
  description = "S3 bucket for RAG documents"
  value       = aws_s3_bucket.rag_docs.id
}

output "rag_table_name" {
  description = "DynamoDB table name for RAG chunks"
  value       = aws_dynamodb_table.rag_table.name
}

output "lambda_role_arn" {
  description = "ARN of Lambda execution role"
  value       = aws_iam_role.lambda_role.arn
}
