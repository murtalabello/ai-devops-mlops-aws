# MLOps Pipeline - Manual Training Guide

This project uses a manual GitHub Actions workflow to train and deploy ML models to AWS.

## Pipeline Overview

### **MLOps Pipeline** (`.github/workflows/train-model.yml`)
Manual trigger (optional daily schedule):
- **Train Model**: Execute scikit-learn training pipeline
- **Publish Model**: Upload artifacts to S3, archive metrics
- **Notifications**: Slack updates on success/failure

## Setup Instructions

### Step 1: Configure GitHub Secrets

Go to **Settings → Secrets and variables → Actions** and add:

```
AWS_REGION                  = us-east-1
AWS_ROLE_ARN               = arn:aws:iam::ACCOUNT_ID:role/GitHubActionsRole
ML_ARTIFACTS_BUCKET        = ai-devops-ml-artifacts-prod
SLACK_WEBHOOK              = https://hooks.slack.com/...
```

### Step 2: Create AWS IAM Role

**GitHub Actions Role** (for OIDC federation):

```bash
aws iam create-role --role-name GitHubActionsRole \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:murtalabello/ai-devops-mlops-aws:*"
        }
      }
    }]
  }'

# Attach S3 policy
aws iam attach-role-policy --role-name GitHubActionsRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
```

### Step 3: Create S3 Bucket for Model Artifacts

```bash
aws s3 mb s3://ai-devops-ml-artifacts-prod --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket ai-devops-ml-artifacts-prod \
  --versioning-configuration Status=Enabled
```

## Triggering Manual Training

### Via GitHub UI:
1. Go to **Actions** → **MLOps - Train & Deploy Model**
2. Click **Run workflow**
3. Select branch: `main`
4. Click **Run workflow**

### Via GitHub CLI:
```bash
gh workflow run train-model.yml --ref main
```

### Via API:
```bash
curl -X POST \
  -H "Authorization: token YOUR_GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+raw" \
  https://api.github.com/repos/murtalabello/ai-devops-mlops-aws/actions/workflows/train-model.yml/dispatches \
  -d '{"ref":"main"}'
```

## Optional: Enable Daily Scheduling

To run training automatically every day at 03:00 UTC, the schedule is already configured in the workflow:

```yaml
schedule:
  - cron: "0 3 * * *"  # Daily at 03:00 UTC
```

To disable: comment out or remove this section from `.github/workflows/train-model.yml`

## Monitoring Training

### GitHub Actions Logs:
1. Go to **Actions** tab → **MLOps - Train & Deploy Model**
2. Click the latest workflow run
3. Expand **train-model** or **publish-model** jobs to view logs

### AWS S3 Artifacts:
```bash
# List all trained models
aws s3 ls s3://ai-devops-ml-artifacts-prod/models/ --recursive

# List all metrics
aws s3 ls s3://ai-devops-ml-artifacts-prod/metrics/ --recursive

# Download latest model
aws s3 cp s3://ai-devops-ml-artifacts-prod/models/ ./ --recursive --exclude "*" --include "model-*.pkl"
```

### Slack Notifications:
Training success/failure will be posted to your Slack channel automatically.

## Training Pipeline Details

### What Gets Trained (`mlops_pipeline/train.py`):
- **Dataset**: Diabetes dataset (scikit-learn)
- **Model**: Linear Regression
- **Train/Test Split**: 80/20
- **Output**: `artifacts/model.pkl` + `artifacts/metrics.txt`

### What Gets Uploaded to S3:
- Model: `s3://ai-devops-ml-artifacts-prod/models/model-YYYYMMDD_HHMMSS.pkl`
- Metrics: `s3://ai-devops-ml-artifacts-prod/metrics/metrics-YYYYMMDD_HHMMSS.txt`

## Local Testing

### Train locally without AWS:
```bash
pip install -r mlops_pipeline/requirements.txt
python mlops_pipeline/train.py
```

Outputs: `artifacts/model.pkl` and `artifacts/metrics.txt`

### Upload artifacts to S3 manually:
```bash
aws s3 cp artifacts/model.pkl s3://ai-devops-ml-artifacts-prod/models/
aws s3 cp artifacts/metrics.txt s3://ai-devops-ml-artifacts-prod/metrics/
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Workflow permission denied | Check AWS_ROLE_ARN secret is correct and role has S3 access |
| S3 upload fails | Verify ML_ARTIFACTS_BUCKET exists and role can write to it |
| Slack notifications not received | Check SLACK_WEBHOOK URL is valid and webhook is active |
| Training script fails | Check Python dependencies in `mlops_pipeline/requirements.txt` |

## Next Steps

- [ ] Set up model versioning and tagging strategy
- [ ] Add model evaluation metrics and performance tracking
- [ ] Implement model registry (SageMaker Model Registry)
- [ ] Add retraining triggers based on data drift
- [ ] Set up automated model deployments to SageMaker endpoints
