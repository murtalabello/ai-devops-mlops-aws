# Quick Start Card

## 🚀 5-Minute Setup

```
1. Clone repo & configure AWS:
   aws configure

2. Run setup script:
   Windows: setup.bat
   Mac/Linux: ./setup.sh

3. Copy outputs into GitHub Secrets (as instructed by script)

4. Go to GitHub Actions and click "Run workflow" on:
   - Deploy Infrastructure (3 min)
   - Deploy DevOps Assistant (2 min)
   - Deploy RAG Service (2 min)
   - MLOps - Train & Deploy (5 min)

Done! Services ready to use.
```

## 📚 Documentation Files

| File | Purpose |
|------|---------|
| **START_HERE.md** | Complete setup & deployment guide (READ THIS FIRST!) |
| **README.md** | Project overview |
| **setup.sh** / **setup.bat** | Automated IAM setup |
| **infra/iam-setup/** | Terraform for IAM roles |
| **infra/main.tf** | AWS resources (S3, DynamoDB, Lambda) |

## 🔧 Commands Cheat Sheet

```bash
# One-time setup (automated by scripts)
./setup.sh                    # macOS/Linux
setup.bat                     # Windows

# Manual IAM setup (if you prefer)
cd infra/iam-setup
terraform init
terraform apply -auto-approve

# Deploy infrastructure
cd infra
terraform init
terraform plan -var-file="environments/prod.tfvars"
terraform apply -var-file="environments/prod.tfvars"

# Cleanup resources
cd infra
terraform destroy -var-file="environments/prod.tfvars"
```

## 📍 Need Help?

1. **Still confused?** Read START_HERE.md thoroughly
2. **Setup failing?** Check AWS credentials: `aws sts get-caller-identity`
3. **Workflow failing?** Check GitHub Secrets are set correctly
4. **Lambda error?** Check CloudWatch logs: `aws logs tail /aws/lambda/FUNCTION_NAME --follow`
5. **Something broken?** Check troubleshooting section in START_HERE.md
