variable "region" {
  type    = string
  default = "us-east-1"
}

variable "ml_artifacts_bucket" {
  type = string
}

variable "rag_docs_bucket" {
  type = string
}

variable "rag_table_name" {
  type = string
}

variable "devops_assistant_package" {
  type = string
}

variable "openai_api_key" {
  type      = string
  sensitive = true
}
