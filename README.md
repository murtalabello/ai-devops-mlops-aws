# AI DevOps MLOps AWS

A comprehensive reference project combining **AI-powered DevOps assistance**, **ML model training pipelines**, and **Retrieval-Augmented Generation (RAG)** on AWS.

## Project Overview

This repository demonstrates integration of three AI/DevOps capabilities:

1. **DevOps Assistant** — Lambda-based service that uses OpenAI to analyze CI/CD logs and suggest fixes
2. **MLOps Pipeline** — Automated model training workflow with S3 artifact storage
3. **RAG Service** — Document ingestion and semantic search with LLM-powered Q&A

## Directory Structure

```
ai-devops-mlops-aws/
├── devops_assistant/
│   ├── lambda_function.py      # AI-powered log analysis (uses OpenAI GPT-4o-mini)
│   └── requirements.txt         # openai, boto3
├── mlops_pipeline/
│   ├── train.py                # Scikit-learn model training script
│   └── requirements.txt         # scikit-learn, numpy, joblib
├── rag_service/
│   ├── lambda_function.py      # Document indexing + semantic search
│   └── requirements.txt         # boto3, openai
├── infra/
│   ├── main.tf                 # AWS resources (S3, DynamoDB, Lambda IAM)
│   ├── variables.tf            # Input variables
│   └── outputs.tf              # Resource outputs
├── .github/workflows/
│   ├── ci.yml                  # CI pipeline with AI DevOps Assistant
│   └── train-model.yml         # MLOps training trigger (daily or manual)
└── README.md
```

## Architecture

### Services

- **DevOps Assistant Lambda**
  - Receives CI/CD build logs via HTTP POST
  - Analyzes with GPT-4o-mini to identify root cause and suggest fixes
  - Returns structured analysis (ROOT_CAUSE, FIX, YAML_PATCH)

- **MLOps Training Pipeline**
  - Scheduled daily or manual trigger via GitHub Actions
  - Trains scikit-learn LinearRegression model on diabetes dataset
  - Saves artifacts to S3 (model + metrics)

- **RAG Service Lambda**
  - `/upload` — ingest documents (base64 encoded), chunk text, generate embeddings
  - `/query` — semantic search with cosine similarity, RAG-based answer generation
  - Uses DynamoDB for chunk storage with OpenAI embeddings

### Infrastructure (Terraform)

- **S3 Buckets**
  - `ml_artifacts_bucket` — trained models, metrics
  - `rag_docs_bucket` — ingested documents

- **DynamoDB Table**
  - `rag_table_name` — document chunks with embeddings

- **IAM Role**
  - Lambda execution role with S3, DynamoDB, OpenAI API permissions

## Setup & Deployment

### Prerequisites

- AWS credentials configured (`~/.aws/credentials`)
- Terraform >= 1.5
- Python 3.11+
- OpenAI API key (for GPT-4o-mini and embeddings)

### Environment Variables & Secrets

Set in GitHub Secrets for workflow runs:
- `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_DEFAULT_REGION`
- `OPENAI_API_KEY`
- `ML_ARTIFACTS_BUCKET`, `RAG_BUCKET`, `RAG_TABLE`
- `AI_ASSISTANT_URL` (Lambda endpoint for DevOps Assistant)

### Deploy Infrastructure

```bash
cd infra
terraform init
terraform plan -var="ml_artifacts_bucket=my-ml-bucket" \
               -var="rag_docs_bucket=my-rag-bucket" \
               -var="rag_table_name=rag-chunks" \
               -var="devops_assistant_package=s3://my-bucket/devops.zip" \
               -var="openai_api_key=sk-..."
terraform apply
```

### Local Development

#### Train Model Locally

```bash
pip install -r mlops_pipeline/requirements.txt
python mlops_pipeline/train.py
```

Output: `artifacts/model.pkl`, `artifacts/metrics.txt`

#### Test DevOps Assistant Locally

```bash
export OPENAI_API_KEY="sk-..."
pip install -r devops_assistant/requirements.txt
python -c "
import json
from devops_assistant.lambda_function import lambda_handler
event = {'body': json.dumps({'log': 'Error: Permission denied'})}
print(lambda_handler(event, None))
"
```

## GitHub Actions Workflows

### CI (`ci.yml`)
- Triggers on push to `main`
- Simulates test failure, captures logs
- Sends logs to DevOps Assistant Lambda for AI-powered debugging

### Train Model (`train-model.yml`)
- Scheduled daily at 03:00 UTC (configurable)
- Can be manually triggered via `workflow_dispatch`
- Trains model, uploads to S3, logs metrics

## Quick Start

1. Clone and navigate to the repo
2. Set GitHub secrets (AWS credentials, OpenAI API key)
3. Deploy infrastructure: `terraform apply` in `infra/`
4. Push to `main` to trigger CI and model training workflows

## Future Enhancements

- [ ] Add SageMaker for distributed training
- [ ] Implement fine-tuned embedding models
- [ ] Add monitoring/alerting with CloudWatch
- [ ] Dockerize Lambda functions for local testing
- [ ] Add cost estimation and optimization reports

## License

MIT
