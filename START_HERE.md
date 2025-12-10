# 🚀 AI DevOps MLOps AWS - Complete Setup & Deployment Guide

**One file. Everything you need. 15 minutes to production.**

---

## 📚 What This Project Does

This project deploys **3 AI-powered microservices** on AWS:

| Service | Purpose | Trigger |
|---------|---------|---------|
| **DevOps Assistant** | Uses OpenAI GPT-4o-mini to analyze CI/CD logs and suggest fixes | Manual API call |
| **RAG Service** | Upload documents, search semantically, get AI-powered answers | Manual API calls |
| **MLOps Pipeline** | Trains ML models daily (or on-demand) using scikit-learn | Manual trigger or daily scheduler |

All services are **serverless (Lambda)**, **scalable**, and **cost-effective** (~$0.25/day during testing).

---

## 🎯 Quick Start (5 Steps)

### Step 1: Prerequisites
- [ ] AWS account (free tier compatible)
- [ ] GitHub account with this repository
- [ ] OpenAI API key (free trial has $5 credits: https://platform.openai.com/api-keys)
- [ ] AWS CLI configured locally: `aws configure`

### Step 2: Set Required Secrets in GitHub
Go to **Settings → Secrets and variables → Actions** and add:

```
OPENAI_API_KEY              = sk-... (from https://platform.openai.com/api-keys)
```

That's it! Everything else is automated via Terraform.

### Step 3: Run Automated IAM Setup Script

**On Windows**:
```bash
cd c:\path\to\ai-devops-mlops-aws
setup.bat
```

**On macOS/Linux**:
```bash
cd /path/to/ai-devops-mlops-aws
chmod +x setup.sh
./setup.sh
```

**What this does**:
- Creates GitHub Actions OIDC role (secure AWS access)
- Creates Lambda execution role
- Outputs role ARNs automatically
- Displays instructions to paste ARNs into GitHub Secrets

**After running**, copy the role ARNs it outputs and add to GitHub Secrets:
```
AWS_ROLE_ARN               = arn:aws:iam::... (script will output this)
AWS_LAMBDA_ROLE_ARN        = arn:aws:iam::... (script will output this)
AWS_REGION                 = us-east-1
```

Alternatively, if you prefer manual Terraform:
```bash
cd infra/iam-setup
terraform init
terraform apply -auto-approve
```

### Step 4: Deploy Infrastructure & Services via GitHub Actions
Go to **GitHub → Actions** and run in order:

1. **Deploy Infrastructure** (3 min) → Creates S3, DynamoDB, IAM
2. **Deploy DevOps Assistant** (2 min) → Lambda + API Gateway
3. **Deploy RAG Service** (2 min) → Lambda + DynamoDB integration
4. **MLOps - Train & Deploy** (5 min) → Model training

**Total: 12-15 minutes**

### Step 5: Test & Verify
```bash
# Get API URLs from GitHub Actions output or AWS API Gateway console
API_URL="https://YOUR_API_ID.execute-api.us-east-1.amazonaws.com/prod"

# Test DevOps Assistant
curl -X POST ${API_URL}/analyze \
  -H "Content-Type: application/json" \
  -d '{"log": "Error: Permission denied"}'

# Test RAG Upload
curl -X POST ${API_URL}/upload \
  -H "Content-Type: application/json" \
  -d '{"filename": "test.txt", "content_base64": "VGVzdCBjb250ZW50"}'

# Test RAG Query
curl -X POST ${API_URL}/query \
  -H "Content-Type: application/json" \
  -d '{"question": "What is in the documents?"}'
```

---

## 🏗️ Project Structure

```
ai-devops-mlops-aws/
├── infra/
│   ├── iam-setup/
│   │   ├── main.tf           # IAM roles & policies (GitHub + Lambda)
│   │   ├── variables.tf       # GitHub org/repo inputs
│   │   └── outputs.tf         # Role ARNs for GitHub Secrets
│   ├── main.tf                # AWS resources (S3, DynamoDB, Lambda)
│   ├── variables.tf           # Input variables
│   └── outputs.tf             # Service endpoints
├── devops_assistant/
│   ├── lambda_function.py     # AI log analyzer
│   └── requirements.txt        # Dependencies
├── rag_service/
│   ├── lambda_function.py     # Document search + Q&A
│   └── requirements.txt        # Dependencies
├── mlops_pipeline/
│   ├── train.py               # Model training script
│   └── requirements.txt        # Dependencies
├── .github/workflows/
│   ├── deploy-infra.yml       # Deploy infrastructure
│   ├── deploy-devops-assistant.yml
│   ├── deploy-rag-service.yml
│   ├── train-model.yml        # Daily training scheduler
│   └── destroy-all.yml        # Clean up all resources
└── START_HERE.md              # This file
```

---

## 🔐 Security & Authentication

**GitHub → AWS Access**: Uses OIDC (OpenID Connect) federation
- No AWS access keys stored in GitHub
- Temporary 1-hour tokens
- Automatically refreshes

**Services**:
- Lambda functions use IAM roles (minimal permissions)
- API Gateway handles authentication (public endpoints for demo)
- OpenAI API key stored as GitHub Secret (encrypted)

---

## 📊 Architecture Overview

```
GitHub Actions Workflows
    ↓
    ├─→ Deploy Infrastructure (Terraform)
    │       ├─ S3 buckets (ml-artifacts, rag-docs)
    │       ├─ DynamoDB table (rag-chunks)
    │       └─ IAM roles
    │
    ├─→ Deploy Lambda Services
    │       ├─ DevOps Assistant (port 8080 → API Gateway)
    │       ├─ RAG Service (port 8081 → API Gateway)
    │       └─ Both connect to S3 + DynamoDB
    │
    └─→ Deploy Training Pipeline
            └─ Scheduled daily OR manual trigger
            └─ Trains model, saves to S3

Users send HTTP requests to API Gateway
    ↓
Lambda functions process requests
    ↓
Services use OpenAI APIs for intelligence
    ↓
Data stored in S3 + DynamoDB
```

---

## 💰 Cost Estimation

| Service | Free Tier | Per 1000 Calls |
|---------|-----------|----------------|
| Lambda | 1M calls/month | $0.20 |
| API Gateway | 1M calls/month | $3.50 |
| S3 | 5GB storage | $0.023/GB |
| DynamoDB | 25 GB/month | Pay-per-request |
| OpenAI API | ~$0.001 per call | $1 |

**POC Testing (2 hours, ~100 calls)**: ~$0.25
**Monthly (moderate use)**: ~$10-20

---

## 🧹 Cleanup (Stop AWS Charges)

After testing, destroy everything:

```bash
# Option 1: Automated (via GitHub Actions)
GitHub Actions → Destroy All Infrastructure → Run workflow
  Type: "destroy-all" (confirmation)
  ⏱️ Takes 5 minutes

# Option 2: Manual (via Terraform)
cd infra
terraform destroy -auto-approve -var-file="environments/prod.tfvars"

cd iam-setup
terraform destroy -auto-approve
```

**Result**: $0 AWS charges, all resources deleted ✅

---

## 🔧 What Each Service Does (Detailed)

### DevOps Assistant Lambda

**Function**: Analyzes CI/CD build logs to identify issues and suggest fixes

**Input**:
```json
{
  "log": "Build failed: TypeError: Cannot read property 'name' of undefined at line 42"
}
```

**Output**:
```json
{
  "ROOT_CAUSE": "Variable 'config' is undefined in the pipeline",
  "FIX": "Initialize config object before using its properties",
  "YAML_PATCH": "Add 'config: {}' to pipeline configuration"
}
```

**Technology**: OpenAI GPT-4o-mini via boto3 + Lambda

---

### RAG Service Lambda

**Function**: Stores documents and answers questions using semantic search + LLM

**Workflow**:
1. User uploads documents (PDF, TXT, JSON)
2. Service chunks text into 500-char segments
3. Creates embeddings using OpenAI text-embedding-3-small
4. Stores in DynamoDB
5. When queried, finds top-5 similar chunks using cosine similarity
6. GPT-4o-mini combines chunks to answer question

**Input** (Upload):
```json
{
  "filename": "deployment-guide.txt",
  "content_base64": "VGhpcyBpcyB0aGUgZGVwbG95bWVudCBndWlkZQ=="
}
```

**Input** (Query):
```json
{
  "question": "How do I deploy this application?"
}
```

**Output**:
```json
{
  "answer": "Based on the documents, deployment involves: 1) Run Terraform init...",
  "sources": ["deployment-guide.txt:chunk-1", "deployment-guide.txt:chunk-3"]
}
```

**Technology**: Boto3 + OpenAI APIs + DynamoDB + cosine similarity

---

### MLOps Training Pipeline

**Function**: Trains ML models automatically (daily or on-demand)

**Workflow**:
1. GitHub Actions triggers (manually or daily at 3 AM UTC)
2. Pulls diabetes dataset from scikit-learn
3. Trains LinearRegression model (80/20 train-test split)
4. Calculates metrics (R², MAE, RMSE)
5. Uploads model.pkl and metrics.txt to S3

**Output Files**:
- `s3://ai-devops-ml-artifacts-prod/models/model_20250209_150000.pkl`
- `s3://ai-devops-ml-artifacts-prod/metrics/metrics_20250209_150000.txt`

**Technology**: scikit-learn + joblib + GitHub Actions + S3

---

## 📖 API Documentation

### DevOps Assistant API

```bash
# Analyze a log
curl -X POST https://API_URL/analyze \
  -H "Content-Type: application/json" \
  -d '{
    "log": "Your build log text here"
  }'

# Response
{
  "statusCode": 200,
  "body": {
    "ROOT_CAUSE": "...",
    "FIX": "...",
    "YAML_PATCH": "..."
  }
}
```

### RAG Service API

```bash
# Upload document
curl -X POST https://API_URL/upload \
  -H "Content-Type: application/json" \
  -d '{
    "filename": "doc.txt",
    "content_base64": "base64_encoded_content"
  }'

# Query documents
curl -X POST https://API_URL/query \
  -H "Content-Type: application/json" \
  -d '{
    "question": "Your question here?"
  }'

# List documents
curl https://API_URL/documents
```

---

## ✅ Deployment Verification Checklist

After each deployment step:

- [ ] GitHub Actions workflow shows ✅ (green checkmark)
- [ ] No errors in GitHub Actions logs
- [ ] AWS Console shows resources created (S3, DynamoDB, Lambda)
- [ ] Slack notification received (if configured)
- [ ] API endpoints working (test with curl commands above)

---

## 🐛 Troubleshooting

| Issue | Solution |
|-------|----------|
| **Workflow fails immediately** | Check GitHub Secrets are set (OPENAI_API_KEY, AWS_ROLE_ARN, etc.) |
| **"Permission denied" errors** | Run IAM Terraform setup: `cd infra/iam-setup && terraform apply -auto-approve` |
| **Lambda function not found** | Run Deploy Infrastructure workflow first before other workflows |
| **API Gateway 502 error** | Check Lambda logs in CloudWatch: `aws logs tail /aws/lambda/devops-assistant-prod --follow` |
| **S3 bucket already exists** | Change bucket name in environments/prod.tfvars (must be globally unique) |
| **DynamoDB errors** | Verify rag-chunks-prod table exists: `aws dynamodb describe-table --table-name rag-chunks-prod` |
| **OpenAI API errors** | Verify API key is valid and has credits: `curl https://api.openai.com/v1/models -H "Authorization: Bearer YOUR_KEY"` |

---

## 🔄 Updating & Maintaining

### Daily Scheduler
The MLOps pipeline runs automatically daily at **3 AM UTC**. To change:
1. Edit `.github/workflows/train-model.yml`
2. Change `cron: '0 3 * * *'` to desired time
3. Push to main branch

### Manual Training
Anytime, run GitHub Actions → MLOps - Train & Deploy Model → Run workflow

### Adding New Features
1. Update Lambda function code
2. Update `requirements.txt` if new packages needed
3. Run corresponding Deploy workflow (e.g., Deploy RAG Service)
4. Terraform will auto-update Lambda code

### Monitoring
- Lambda logs: AWS CloudWatch → Logs
- API metrics: API Gateway → CloudWatch
- Model performance: Check S3 metrics files
- Costs: AWS Cost Explorer

---

## 📚 Additional Resources

| Resource | Link |
|----------|------|
| **AWS Lambda** | https://docs.aws.amazon.com/lambda/ |
| **OpenAI API** | https://platform.openai.com/docs/ |
| **Terraform AWS** | https://registry.terraform.io/providers/hashicorp/aws/ |
| **GitHub Actions** | https://docs.github.com/en/actions |
| **DynamoDB** | https://docs.aws.amazon.com/dynamodb/ |

---

## 💡 Next Steps After Deployment

1. **Test all 3 services** using curl commands above
2. **Monitor CloudWatch logs** to understand service behavior
3. **Experiment with prompts** to DevOps Assistant for different log scenarios
4. **Upload sample documents** to RAG Service and test semantic search
5. **Check S3 for trained models** and review performance metrics
6. **Clean up resources** using destroy-all workflow to avoid charges

---

## ❓ Questions?

- Check logs: `GitHub Actions → Workflow run → Click job → View logs`
- Check AWS resources: AWS Console → Lambda/S3/DynamoDB/API Gateway
- Review error messages in GitHub Actions output
- Check CloudWatch logs: `aws logs tail /aws/lambda/FUNCTION_NAME --follow`

---

**You're ready to deploy! Start with Step 1 above. 🚀**
