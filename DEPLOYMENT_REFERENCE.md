# Quick Reference - Deployment & Cleanup

## 📋 Deployment Workflows Available

| Workflow | Purpose | Time | Status |
|----------|---------|------|--------|
| `deploy-infra.yml` | Create AWS resources (S3, DynamoDB, IAM) | 3 min | ✅ Ready |
| `deploy-devops-assistant.yml` | Deploy DevOps Assistant Lambda | 2 min | ✅ Ready |
| `deploy-rag-service.yml` | Deploy RAG Service Lambda | 2 min | ✅ Ready |
| `train-model.yml` | Train ML model (manual or daily) | 5 min | ✅ Ready |
| `destroy-all.yml` | **Clean up all resources** | 5 min | ✅ Ready |

---

## 🎯 Deployment Steps (in order)

### Step 1: Deploy Infrastructure
```
GitHub Actions → Deploy Infrastructure → Run workflow
  Environment: prod
  ⏱️ Wait: ~3 minutes
```

### Step 2: Deploy DevOps Assistant
```
GitHub Actions → Deploy DevOps Assistant → Run workflow
  Environment: prod
  ⏱️ Wait: ~2 minutes
```

### Step 3: Deploy RAG Service
```
GitHub Actions → Deploy RAG Service → Run workflow
  Environment: prod
  ⏱️ Wait: ~2 minutes
```

### Step 4: Deploy MLOps Pipeline
```
GitHub Actions → MLOps - Train & Deploy Model → Run workflow
  Environment: prod
  ⏱️ Wait: ~5 minutes
```

**Total deployment time: 12-15 minutes**

---

## 🧹 Cleanup (After POC Testing)

### Option 1: Automated Cleanup (Recommended)
```
GitHub Actions → Destroy All Infrastructure → Run workflow
  Environment: prod
  Confirm: destroy-all (type exactly as shown)
  ⏱️ Wait: ~5 minutes
```

**This will**:
- ✅ Backup all data before deletion
- ✅ Delete Lambda functions
- ✅ Delete API Gateways
- ✅ Delete S3 buckets
- ✅ Delete DynamoDB tables
- ✅ Delete IAM roles
- ✅ Send Slack notification

### Option 2: Manual Cleanup
```bash
# Using AWS CLI
cd infra
terraform destroy -auto-approve -var-file="environments/prod.tfvars"

# Delete remaining resources manually if needed
aws lambda delete-function --function-name devops-assistant-prod
aws lambda delete-function --function-name rag-service-prod
aws apigateway delete-rest-api --rest-api-id <API_ID>
aws s3 rb s3://ai-devops-ml-artifacts-prod --force
aws s3 rb s3://ai-devops-rag-docs-prod --force
aws dynamodb delete-table --table-name rag-chunks-prod
```

---

## 💰 Cost Summary for POC

**Per day of testing**: ~$0.25 (mostly Lambda and API Gateway calls)

**Total POC cost** (1-2 hours): ~$0.25

**After cleanup**: $0 (all resources deleted)

---

## ✅ Verification Checklist

After each deployment, verify:

- [ ] Workflow completed without errors in GitHub Actions
- [ ] Slack notification received (if configured)
- [ ] Can see Lambda functions in AWS Console
- [ ] Can see API Gateway endpoints in AWS Console
- [ ] S3 buckets visible and contain expected files (after training)

---

## 📞 Troubleshooting

| Issue | Fix |
|-------|-----|
| Workflow fails immediately | Check all GitHub Secrets are configured |
| Lambda deployment fails | Verify AWS_LAMBDA_ROLE_ARN is correct |
| API Gateway not working | Check Lambda has API Gateway invoke permission |
| Destroy fails | Use manual cleanup commands or check for orphaned resources |

---

## 📚 Full Documentation

- **PROJECT_OVERVIEW.md** - High-level overview of all 3 services
- **DEPLOYMENT.md** - Detailed deployment instructions
- **README.md** - Project structure and dependencies
- **DEPLOYMENT_REFERENCE.md** - This file

---

**Need help?** Check the detailed DEPLOYMENT.md file or GitHub Actions logs for error messages.
