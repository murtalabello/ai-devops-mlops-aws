# Automated Deployment Guide

This project uses GitHub Actions pipelines to automatically build, test, and deploy the AI DevOps MLOps application to AWS.

## Pipeline Overview

### 1. **CI/CD Pipeline** (`.github/workflows/ci.yml`)
Triggered on push to `main` branch:
- **Lint & Test**: Python linting, security scanning (bandit)
- **Build Lambdas**: Package devops-assistant and rag-service functions
- **Deploy to AWS**: 
  - Initialize and apply Terraform
  - Deploy Lambda functions
  - Create API Gateway endpoints
  - Run smoke tests
  - Send Slack notifications

### 2. **MLOps Pipeline** (`.github/workflows/train-model.yml`)
Scheduled daily at 03:00 UTC (or manual trigger):
- **Train Model**: Execute scikit-learn training pipeline
- **Publish Model**: Upload artifacts to S3, archive metrics
- **Notifications**: Slack updates on success/failure

### 3. **Manual Deploy Workflow** (`.github/workflows/deploy.yml`)
Manual trigger with environment selection (dev/staging/prod):
- Allows choosing target environment
- Runs full deployment pipeline
- Notifications on completion

## Setup Instructions

### Step 1: Configure GitHub Secrets

Go to **Settings → Secrets and variables → Actions** and add:

```
AWS_REGION                  = us-east-1
AWS_ROLE_ARN               = arn:aws:iam::ACCOUNT_ID:role/GitHubActionsRole
AWS_LAMBDA_ROLE_ARN        = arn:aws:iam::ACCOUNT_ID:role/ai_platform_lambda_role
TF_STATE_BUCKET            = terraform-state-ACCOUNT_ID
OPENAI_API_KEY             = sk-...
ML_ARTIFACTS_BUCKET        = ai-devops-ml-artifacts-prod
SLACK_WEBHOOK              = https://hooks.slack.com/...
```

### Step 2: Create AWS IAM Roles

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

# Attach policies
aws iam attach-role-policy --role-name GitHubActionsRole \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
```

**Lambda Role** (for function execution):

```bash
aws iam create-role --role-name ai_platform_lambda_role \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {"Service": "lambda.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }]
  }'

# Attach policies for S3, DynamoDB, CloudWatch
aws iam attach-role-policy --role-name ai_platform_lambda_role \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess

aws iam attach-role-policy --role-name ai_platform_lambda_role \
  --policy-arn arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess

aws iam attach-role-policy --role-name ai_platform_lambda_role \
  --policy-arn arn:aws:iam::aws:policy/CloudWatchLogsFullAccess
```

### Step 3: Create Terraform State S3 Bucket

```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

aws s3 mb s3://terraform-state-${ACCOUNT_ID} \
  --region us-east-1 \
  --create-bucket-configuration LocationConstraint=us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket terraform-state-${ACCOUNT_ID} \
  --versioning-configuration Status=Enabled
```

### Step 4: Push to Trigger Deployment

```bash
git add .
git commit -m "Deploy automated pipeline"
git push origin main
```

This will trigger the CI/CD pipeline automatically!

## Local Testing

### Run deployment script locally:

```bash
# Set environment variables
export AWS_REGION=us-east-1
export ENVIRONMENT=dev
export OPENAI_API_KEY=sk-...

# Make scripts executable
chmod +x scripts/*.sh

# Run deployment
bash scripts/deploy.sh
```

### Run smoke tests:

```bash
bash scripts/smoke-tests.sh \
  "https://API_ID.execute-api.us-east-1.amazonaws.com/dev/" \
  "https://API_ID.execute-api.us-east-1.amazonaws.com/dev/"
```

### Teardown (destroy resources):

```bash
bash scripts/teardown.sh dev
```

## Pipeline Variables

### In `infra/environments/dev.tfvars`:
- `region`: AWS region
- `ml_artifacts_bucket`: S3 bucket for ML models
- `rag_docs_bucket`: S3 bucket for RAG documents
- `rag_table_name`: DynamoDB table name
- `devops_assistant_package`: Lambda package name

## Monitoring & Logs

### GitHub Actions Logs:
- Go to **Actions** tab → click workflow run → view logs

### AWS CloudWatch Logs:
```bash
# DevOps Assistant Lambda
aws logs tail /aws/lambda/devops-assistant-prod --follow

# RAG Service Lambda
aws logs tail /aws/lambda/rag-service-prod --follow
```

### AWS Cost Monitoring:
```bash
aws ce get-cost-and-usage \
  --time-period Start=2025-01-01,End=2025-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Pipeline fails on Terraform | Check TF state bucket exists and role has permissions |
| Lambda deployment fails | Verify AWS_LAMBDA_ROLE_ARN exists and has S3/DynamoDB access |
| API Gateway not responding | Check Lambda permission for API Gateway principal |
| Smoke tests timeout | Verify security groups allow outbound HTTPS |
| OpenAI API errors | Validate OPENAI_API_KEY is correct and has quota |

## Rollback

To rollback to previous deployment:

```bash
cd infra
terraform destroy -auto-approve -var-file="environments/prod.tfvars"
# Or restore from S3 state backup
aws s3 cp s3://terraform-state-ACCOUNT_ID/ai-devops-prod-backup.tfstate ./terraform.tfstate
terraform apply
```

## Next Steps

- [ ] Set up CloudWatch dashboards for monitoring
- [ ] Integrate with PagerDuty for on-call alerting
- [ ] Add automated cost optimization checks
- [ ] Enable canary deployments for safer rollouts
- [ ] Set up database backups and disaster recovery
