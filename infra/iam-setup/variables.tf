variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "github_org" {
  description = "GitHub organization or username"
  type        = string
  default     = "murtalabello"
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
  default     = "ai-devops-mlops-aws"
}
