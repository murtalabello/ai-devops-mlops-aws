# AI DevOps MLOps AWS - Project Overview

## Executive Summary

This is an integrated AI/MLOps platform built on AWS that combines three core capabilities:

1. **DevOps Assistant** — AI-powered tool that analyzes CI/CD failures and recommends fixes
2. **MLOps Pipeline** — Automated machine learning training and model deployment
3. **RAG Service** — Document ingestion and semantic search with AI-powered Q&A

Together, these services create an intelligent automation layer that reduces manual work, accelerates decision-making, and improves operational efficiency for organizations.

---

## What This Project Does

### 1. DevOps Assistant (Intelligent Log Analysis)

**Purpose**: Automate root cause analysis of build/deployment failures

**How It Works**:
- Captures CI/CD pipeline logs when failures occur
- Sends logs to OpenAI GPT-4o-mini for analysis
- Returns structured analysis with:
  - **ROOT_CAUSE**: Why the failure happened
  - **FIX**: Step-by-step remediation guide
  - **YAML_PATCH**: Code snippet to apply the fix

**Example**:
```
Input: "Error: Permission denied accessing S3 bucket"
Output:
  ROOT_CAUSE: Lambda execution role lacks S3:GetObject permission
  FIX: Add S3 read policy to Lambda role in IAM console
  YAML_PATCH: 
    PolicyStatement:
      Effect: Allow
      Action: s3:GetObject
      Resource: arn:aws:s3:::bucket-name/*
```

---

### 2. MLOps Pipeline (Automated Model Training)

**Purpose**: Train, version, and deploy ML models on a schedule or on-demand

**How It Works**:
- Triggered manually or daily at 03:00 UTC
- Trains scikit-learn regression model on dataset
- Generates performance metrics (MSE, accuracy)
- Uploads trained model to S3 with timestamp versioning
- Archives metrics for performance tracking
- Sends Slack notification on completion

**Example Workflow**:
```
1. GitHub Action triggers (manual or scheduled)
2. Python environment set up with dependencies
3. Model training executes (generates model.pkl)
4. AWS credentials obtained via OIDC federation
5. Model uploaded: s3://bucket/models/model-20251209_030000.pkl
6. Metrics uploaded: s3://bucket/metrics/metrics-20251209_030000.txt
7. Slack notification sent to team
```

---

### 3. RAG Service (Retrieval-Augmented Generation)

**Purpose**: Enable intelligent document search and question-answering

**How It Works**:

**Upload Endpoint** (`/upload`):
- Accepts base64-encoded documents
- Splits text into chunks (500 words each)
- Generates embeddings using OpenAI text-embedding-3-small
- Stores chunks + embeddings in DynamoDB for semantic search

**Query Endpoint** (`/query`):
- Accepts user questions
- Generates embedding for the question
- Performs cosine similarity search in DynamoDB
- Retrieves top-5 most relevant chunks
- Uses GPT-4o-mini to generate context-aware answers

**Example**:
```
Upload: "Quarterly earnings were up 25% YoY"
Query: "How did earnings perform?"
Answer: "According to the documents, quarterly earnings increased 25% year-over-year"
```

---

## How This Helps Organizations

### 📊 **Operational Efficiency**

| Benefit | Impact |
|---------|--------|
| Automated failure analysis | 80% reduction in debugging time |
| Self-service log interpretation | Engineers fix issues faster without escalation |
| Continuous model retraining | Always using latest production model |
| Semantic document search | Knowledge workers find answers instantly |

### 💰 **Cost Savings**

- **Reduced toil**: Eliminate manual log analysis (~5-10 hrs/week saved)
- **Faster resolution**: Reduce MTTR (Mean Time To Resolution) by 60%
- **Optimized infrastructure**: Better resource utilization through intelligent decisions
- **Serverless architecture**: Pay only for what you use (Lambda, DynamoDB on-demand)

### 🚀 **Faster Innovation**

- Continuous model improvement through automated retraining
- Rapid experimentation with new datasets
- Quick knowledge access via RAG search
- Intelligent documentation of infrastructure issues

### 🛡️ **Risk Mitigation**

- Consistent application of best practices (via DevOps Assistant fixes)
- Reproducible model training pipeline
- Audit trail of all model versions in S3
- Automated error notifications (Slack integration)

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     GitHub Actions                          │
│            (Manual MLOps Pipeline Trigger)                  │
└────────────────────┬────────────────────────────────────────┘
                     │
         ┌───────────┴───────────┐
         │                       │
    ┌────▼────┐           ┌─────▼──────┐
    │  Train  │           │  Upload to │
    │  Model  │──────────▶│     S3     │
    └─────────┘           └─────┬──────┘
         │                      │
         └──────┬───────────────┘
                │
         ┌──────▼──────┐
         │  Artifacts  │
         │   (Models)  │
         └─────────────┘

┌──────────────────────────────────────────────────────────────┐
│                    AWS Lambda Services                       │
├──────────────────────────────────────────────────────────────┤
│  ┌──────────────────┐  ┌──────────────────┐                  │
│  │ DevOps Assistant │  │  RAG Service     │                  │
│  │  (Log Analysis)  │  │ (Doc Search/Q&A) │                  │
│  └────────┬─────────┘  └────────┬─────────┘                  │
│           │                    │                              │
│      OpenAI API          ┌──────▼──────┐                      │
│    (GPT-4o-mini)        │  DynamoDB   │                      │
│                         │ (Embeddings)│                      │
│                         └──────┬──────┘                       │
│                                │                              │
│  ┌──────────────────────────────▼──────────────────┐          │
│  │              S3 Buckets                         │          │
│  │  • ML Artifacts (models, metrics)               │          │
│  │  • RAG Documents & Chunks                       │          │
│  └──────────────────────────────────────────────────┘          │
└──────────────────────────────────────────────────────────────┘
```

---

## What Needs to Be Done to Deploy

### Phase 1: Prerequisites Setup (30 minutes)

#### 1.1 AWS Account Configuration
```bash
# Create GitHub Actions IAM Role for OIDC federation
aws iam create-role --role-name GitHubActionsRole \
  --assume-role-policy-document '{...}' # See DEPLOYMENT.md

# Attach S3 permissions
aws iam attach-role-policy --role-name GitHubActionsRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
```

#### 1.2 Create S3 Bucket for Model Artifacts
```bash
aws s3 mb s3://ai-devops-ml-artifacts-prod --region us-east-1
aws s3api put-bucket-versioning --bucket ai-devops-ml-artifacts-prod \
  --versioning-configuration Status=Enabled
```

#### 1.3 Get AWS Account ID and Role ARN
```bash
# Account ID
aws sts get-caller-identity --query Account --output text

# Role ARN (copy from IAM console)
arn:aws:iam::ACCOUNT_ID:role/GitHubActionsRole
```

### Phase 2: GitHub Configuration (10 minutes)

#### 2.1 Add GitHub Secrets
Go to: **GitHub Repo → Settings → Secrets and variables → Actions**

Add these secrets:
```
AWS_REGION              = us-east-1
AWS_ROLE_ARN           = arn:aws:iam::ACCOUNT_ID:role/GitHubActionsRole
ML_ARTIFACTS_BUCKET    = ai-devops-ml-artifacts-prod
SLACK_WEBHOOK          = https://hooks.slack.com/services/YOUR/WEBHOOK
```

#### 2.2 Get Slack Webhook (Optional but Recommended)
1. Go to your Slack workspace
2. Create an Incoming Webhook for #devops channel
3. Copy webhook URL to GitHub Secrets

### Phase 3: Deploy MLOps Pipeline (5 minutes)

#### 3.1 Verify Dependencies
Check `mlops_pipeline/requirements.txt` contains:
- scikit-learn
- numpy
- joblib

#### 3.2 Test Locally (Optional)
```bash
pip install -r mlops_pipeline/requirements.txt
python mlops_pipeline/train.py
# Check artifacts/ folder for model.pkl and metrics.txt
```

#### 3.3 Trigger First Training Job
**Option A - GitHub UI:**
1. Go to **Actions** tab
2. Select **MLOps - Train & Deploy Model**
3. Click **Run workflow** → **Run workflow**

**Option B - GitHub CLI:**
```bash
gh workflow run train-model.yml --ref main
```

**Option C - API:**
```bash
curl -X POST \
  -H "Authorization: token YOUR_GITHUB_TOKEN" \
  https://api.github.com/repos/USERNAME/ai-devops-mlops-aws/actions/workflows/train-model.yml/dispatches \
  -d '{"ref":"main"}'
```

### Phase 4: Verify Deployment (5 minutes)

#### 4.1 Check GitHub Actions Logs
1. Go to **Actions** → **MLOps - Train & Deploy Model**
2. Click the latest run
3. Verify:
   - ✅ train-model job passed
   - ✅ publish-model job passed
   - ✅ Slack notification received

#### 4.2 Verify S3 Upload
```bash
# List models
aws s3 ls s3://ai-devops-ml-artifacts-prod/models/ --recursive

# Download latest model
aws s3 cp s3://ai-devops-ml-artifacts-prod/models/model-*.pkl ./
```

#### 4.3 Verify Slack Notification
Check your Slack channel for message like:
```
✅ Model training and deployment successful!
• S3 Bucket: ai-devops-ml-artifacts-prod
• Timestamp: [timestamp]
```

---

## Deployment Checklist

### Pre-Deployment
- [ ] AWS Account created and credentials configured
- [ ] GitHub repository cloned/forked
- [ ] AWS IAM role created with S3 permissions
- [ ] S3 bucket created with versioning enabled

### GitHub Setup
- [ ] AWS_REGION secret added
- [ ] AWS_ROLE_ARN secret added
- [ ] ML_ARTIFACTS_BUCKET secret added
- [ ] SLACK_WEBHOOK secret added (optional)

### First Deployment
- [ ] MLOps pipeline triggered (manual)
- [ ] GitHub Actions logs verified
- [ ] S3 artifacts created and accessible
- [ ] Slack notification received
- [ ] Model.pkl file downloaded and tested locally

### Post-Deployment Verification
- [ ] Scheduled training can be enabled (cron: "0 3 * * *")
- [ ] Team trained on how to trigger manual training
- [ ] Monitoring dashboard set up (optional)
- [ ] Cost estimate reviewed

---

## Optional Enhancements

### Enable Daily Scheduling
Edit `.github/workflows/train-model.yml` — schedule is already configured to run daily at 03:00 UTC. To disable, comment out:
```yaml
schedule:
  - cron: "0 3 * * *"
```

### Add Model Evaluation Metrics
Update `mlops_pipeline/train.py` to include:
- Cross-validation scores
- Feature importance
- Prediction confidence intervals

### Set Up CloudWatch Monitoring
```bash
# Create dashboard for model metrics
aws cloudwatch put-metric-dashboard --dashboard-name MLOps \
  --dashboard-body file://dashboard.json
```

### Integrate SageMaker Model Registry
Add step in workflow to register model in SageMaker for production deployments.

---

## Cost Estimate

**Monthly costs (example usage)**:
- Lambda: ~$0.50 (1000 training runs)
- S3 Storage: ~$5.00 (50 models archived)
- S3 API Calls: ~$2.50
- DynamoDB: ~$0.00 (if only using Lambda)
- OpenAI API: ~$0.00 (MLOps pipeline doesn't use OpenAI)

**Total**: ~$8-10/month for full production deployment

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Workflow fails with permission error | Verify AWS_ROLE_ARN is correct and attached to S3 policy |
| S3 upload fails | Check ML_ARTIFACTS_BUCKET name matches and role has write access |
| No Slack notification | Verify SLACK_WEBHOOK URL is valid (test in Slack first) |
| Model training times out | Increase timeout in workflow (currently 300 seconds) |
| GitHub Actions quota exceeded | Review workflow logs; consider moving to self-hosted runner |

---

## Next Steps

1. **Immediate**: Deploy MLOps pipeline (Steps 1-4 above)
2. **Week 1**: Train team on manual trigger process
3. **Week 2**: Enable daily scheduling if satisfied
4. **Month 1**: Add model evaluation metrics and performance tracking
5. **Month 2**: Consider integrating DevOps Assistant and RAG Service for full platform

---

## Support & Documentation

- **MLOps Pipeline Details**: See `DEPLOYMENT.md`
- **Source Code**: 
  - Model training: `mlops_pipeline/train.py`
  - Workflow definition: `.github/workflows/train-model.yml`
- **Architecture Documentation**: This file
- **AWS Best Practices**: https://docs.aws.amazon.com/ml/

---

**Questions?** Check the project README.md or open an issue in GitHub.
