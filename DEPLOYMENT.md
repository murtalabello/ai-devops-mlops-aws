# Complete Deployment Guide - All 3 Services

This guide will walk you through deploying all three services of the AI DevOps MLOps platform.

## Services Overview

| Service | Purpose | Type | Deployment |
|---------|---------|------|-----------|
| **DevOps Assistant** | AI-powered CI/CD log analysis | Lambda + API Gateway | Manual workflow |
| **RAG Service** | Document search & AI Q&A | Lambda + DynamoDB + S3 | Manual workflow |
| **MLOps Pipeline** | Model training & versioning | Lambda + S3 | Manual + Scheduled |

---

## Prerequisites

### Step 1: Set Up AWS Account (15 minutes)

#### 1.1 Create IAM Role for GitHub Actions (OIDC)

```bash
# Get your GitHub repo info
GITHUB_ORG="murtalabello"
GITHUB_REPO="ai-devops-mlops-aws"

# Create role with OIDC trust relationship
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
          "token.actions.githubusercontent.com:sub": "repo:'$GITHUB_ORG'/'$GITHUB_REPO':*"
        }
      }
    }]
  }'

# Attach necessary policies
aws iam attach-role-policy --role-name GitHubActionsRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess

aws iam attach-role-policy --role-name GitHubActionsRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess

aws iam attach-role-policy --role-name GitHubActionsRole \
  --policy-arn arn:aws:iam::aws:policy/AWSLambda_FullAccess

aws iam attach-role-policy --role-name GitHubActionsRole \
  --policy-arn arn:aws:iam::aws:policy/APIGatewayFullAccess
```

#### 1.2 Create Lambda Execution Role

```bash
aws iam create-role --role-name ai-platform-lambda-role \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {"Service": "lambda.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }]
  }'

# Attach policies
aws iam attach-role-policy --role-name ai-platform-lambda-role \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess

aws iam attach-role-policy --role-name ai-platform-lambda-role \
  --policy-arn arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess

aws iam attach-role-policy --role-name ai-platform-lambda-role \
  --policy-arn arn:aws:iam::aws:policy/CloudWatchLogsFullAccess
```

#### 1.3 Create S3 Buckets

```bash
# ML Artifacts bucket
aws s3 mb s3://ai-devops-ml-artifacts-prod --region us-east-1
aws s3api put-bucket-versioning --bucket ai-devops-ml-artifacts-prod \
  --versioning-configuration Status=Enabled

# RAG Documents bucket
aws s3 mb s3://ai-devops-rag-docs-prod --region us-east-1
aws s3api put-bucket-versioning --bucket ai-devops-rag-docs-prod \
  --versioning-configuration Status=Enabled
```

#### 1.4 Get Your AWS Account ID and Role ARN

```bash
# Account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "Account ID: $ACCOUNT_ID"

# GitHub Actions Role ARN
AWS_ROLE_ARN="arn:aws:iam::$ACCOUNT_ID:role/GitHubActionsRole"
echo "GitHub Actions Role ARN: $AWS_ROLE_ARN"

# Lambda Role ARN
LAMBDA_ROLE_ARN="arn:aws:iam::$ACCOUNT_ID:role/ai-platform-lambda-role"
echo "Lambda Role ARN: $LAMBDA_ROLE_ARN"
```

### Step 2: Configure GitHub Secrets (10 minutes)

Go to **GitHub Repo → Settings → Secrets and variables → Actions**

Add the following secrets:

```
AWS_REGION                  = us-east-1
AWS_ROLE_ARN               = arn:aws:iam::ACCOUNT_ID:role/GitHubActionsRole
AWS_LAMBDA_ROLE_ARN        = arn:aws:iam::ACCOUNT_ID:role/ai-platform-lambda-role
OPENAI_API_KEY             = sk-YOUR_OPENAI_API_KEY
ML_ARTIFACTS_BUCKET        = ai-devops-ml-artifacts-prod
RAG_BUCKET_NAME            = ai-devops-rag-docs-prod
RAG_TABLE_NAME             = rag-chunks-prod
SLACK_WEBHOOK              = https://hooks.slack.com/services/YOUR/WEBHOOK/URL
```

---

## Deployment Steps

### Phase 1: Deploy Infrastructure (Terraform)

**Why**: Creates AWS resources (S3 buckets, DynamoDB table, IAM roles)

**Steps**:

1. Go to **Actions** tab in GitHub
2. Click **Deploy Infrastructure** workflow
3. Click **Run workflow**
4. Select environment: `prod` (or `dev` for testing)
5. Click **Run workflow**

**Expected output**:
- ✅ S3 buckets created
- ✅ DynamoDB table created
- ✅ IAM role for Lambda created
- ✅ Slack notification (if configured)

**Verify**:
```bash
# Check S3 buckets
aws s3 ls | grep ai-devops

# Check DynamoDB tables
aws dynamodb list-tables --region us-east-1
```

---

### Phase 2: Deploy DevOps Assistant Service

**What it does**: AI-powered CI/CD log analysis Lambda function

**Steps**:

1. Go to **Actions** tab
2. Click **Deploy DevOps Assistant**
3. Click **Run workflow**
4. Select environment: `prod`
5. Click **Run workflow**

**Expected output**:
- ✅ Lambda function created: `devops-assistant-prod`
- ✅ API Gateway endpoint created
- ✅ Slack notification with API URL

**Test**:
```bash
# Get API Gateway URL from workflow logs or AWS Console
API_URL="https://YOUR_API_ID.execute-api.us-east-1.amazonaws.com/prod/"

# Test the endpoint
curl -X POST $API_URL \
  -H "Content-Type: application/json" \
  -d '{"log": "Error: Permission denied accessing S3"}'
```

**Expected response**:
```json
{
  "analysis": "ROOT_CAUSE: Lambda execution role lacks S3:GetObject permission...",
  "statusCode": 200
}
```

---

### Phase 3: Deploy RAG Service

**What it does**: Document ingestion and semantic search with AI Q&A

**Steps**:

1. Go to **Actions** tab
2. Click **Deploy RAG Service**
3. Click **Run workflow**
4. Select environment: `prod`
5. Click **Run workflow**

**Expected output**:
- ✅ Lambda function created: `rag-service-prod`
- ✅ API Gateway endpoint created with `/upload` and `/query` routes
- ✅ DynamoDB connected for embeddings storage
- ✅ Slack notification with API URL

**Test Upload**:
```bash
API_URL="https://YOUR_API_ID.execute-api.us-east-1.amazonaws.com/prod/"

# Create a sample document
CONTENT=$(echo "The quarterly earnings were up 25% year-over-year" | base64)

# Upload to RAG
curl -X POST "${API_URL}upload" \
  -H "Content-Type: application/json" \
  -d "{\"filename\": \"earnings.txt\", \"content_base64\": \"$CONTENT\"}"
```

**Expected response**:
```json
{
  "status": "indexed",
  "chunks": 1
}
```

**Test Query**:
```bash
# Ask a question
curl -X POST "${API_URL}query" \
  -H "Content-Type: application/json" \
  -d '{"question": "How did earnings perform?"}'
```

**Expected response**:
```json
{
  "answer": "According to the documents, quarterly earnings increased 25% year-over-year"
}
```

---

### Phase 4: Deploy MLOps Pipeline

**What it does**: Train ML models and version them in S3

**Steps**:

1. Go to **Actions** tab
2. Click **MLOps - Train & Deploy Model**
3. Click **Run workflow**
4. Select environment: `prod`
5. Click **Run workflow**

**Expected output**:
- ✅ Model training completed
- ✅ Model uploaded to S3: `s3://ai-devops-ml-artifacts-prod/models/model-prod-TIMESTAMP.pkl`
- ✅ Metrics uploaded: `s3://ai-devops-ml-artifacts-prod/metrics/metrics-prod-TIMESTAMP.txt`
- ✅ Slack notification

**Verify**:
```bash
# List trained models
aws s3 ls s3://ai-devops-ml-artifacts-prod/models/ --recursive

# Download and inspect latest model
aws s3 cp s3://ai-devops-ml-artifacts-prod/models/model-prod-*.pkl ./
file model-prod-*.pkl  # Should be a Python pickle file
```

---

## Complete Deployment Summary

| Service | Status | API Endpoint | Duration |
|---------|--------|-------------|----------|
| Infrastructure (Terraform) | ✅ | N/A | ~3 min |
| DevOps Assistant | ✅ | `/log-analysis` | ~2 min |
| RAG Service | ✅ | `/upload`, `/query` | ~2 min |
| MLOps Pipeline | ✅ | S3 (artifacts) | ~5 min |

**Total Deployment Time**: ~15-20 minutes

---

## Monitoring & Verification

### GitHub Actions
- Check workflow runs: GitHub → Actions tab
- View logs: Click workflow run → click job

### AWS Console
- Lambda functions: Lambda → Functions
- API Gateway: API Gateway → APIs
- S3 buckets: S3 → Buckets
- DynamoDB tables: DynamoDB → Tables
- CloudWatch logs: CloudWatch → Logs

### Commands to Verify All Services

```bash
# 1. List Lambda functions
aws lambda list-functions --region us-east-1 \
  --query 'Functions[?contains(FunctionName, `prod`)].FunctionName'

# 2. List API Gateways
aws apigateway get-rest-apis --region us-east-1 \
  --query 'Items[?contains(name, `prod`)].{Name:name,Id:id}'

# 3. List S3 artifacts
aws s3 ls s3://ai-devops-ml-artifacts-prod/models/ --recursive
aws s3 ls s3://ai-devops-rag-docs-prod/ --recursive

# 4. Check DynamoDB
aws dynamodb describe-table --table-name rag-chunks-prod --region us-east-1
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Workflow permission denied | Verify AWS_ROLE_ARN is correct and OIDC trust relationship is set up |
| Lambda creation fails | Check AWS_LAMBDA_ROLE_ARN is correct and has necessary permissions |
| API Gateway not responding | Verify Lambda has API Gateway invoke permission |
| S3 upload fails | Check bucket name in secrets and role has S3 permissions |
| DynamoDB errors | Verify RAG_TABLE_NAME secret matches created table name |
| Slack notification fails | Check SLACK_WEBHOOK URL is valid |

---

## Next Steps

### After Successful Deployment

1. **Test All Services**: Follow test commands in each phase above
2. **Monitor Logs**: Check CloudWatch for any errors
3. **Enable Scheduling** (Optional): MLOps already scheduled to run daily at 03:00 UTC
4. **Set Up Alerts** (Optional): Create CloudWatch alarms for failures
5. **Document Integration Points**: Record API endpoints for team use

### Future Enhancements

- [ ] Add CI/CD pipeline for automatic testing on push
- [ ] Integrate with Slack for real-time alerting
- [ ] Add cost monitoring and optimization
- [ ] Set up SageMaker for distributed training
- [ ] Add model performance dashboards

---

## Support

For issues or questions:
1. Check GitHub Actions logs for detailed error messages
2. Review AWS CloudWatch logs for service errors
3. Verify all GitHub Secrets are correctly configured
4. Ensure AWS IAM roles have proper permissions

---

**Deployment Complete!** 🎉

All three services are now deployed and ready to use. Visit GitHub Actions to trigger workflows and monitor execution.
