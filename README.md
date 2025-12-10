# AI DevOps MLOps AWS Platform

Deploy **3 AI-powered serverless services** on AWS in **20 minutes** with **zero manual AWS CLI commands**.

## What Gets Deployed

| Service | What It Does | How To Use |
|---------|-------------|-----------|
| **DevOps Assistant** | Uses OpenAI GPT-4o-mini to analyze build logs and suggest fixes | Send CI/CD logs via API → Get AI-powered debugging |
| **RAG Service** | Upload documents, search them semantically, ask AI questions | Upload PDFs/text → Ask questions → Get answers from your docs |
| **MLOps Pipeline** | Trains ML models automatically (daily or on-demand) | GitHub Actions trigger → Model trains → Results saved to S3 |

**All serverless.** **All scalable.** **~$0.25/day during POC.**

---

## Step-by-Step Setup (No Assumptions)

### 1️⃣ Before You Start

Check these boxes:

- [ ] You have an AWS account (free tier is fine)
- [ ] You have this GitHub repository 
- [ ] You have AWS CLI installed on your computer
- [ ] You have Terraform installed on your computer
- [ ] You have an OpenAI API key (get free credits at https://platform.openai.com/api-keys)

**Don't have AWS CLI?** [Install it here](https://aws.amazon.com/cli/)

**Don't have Terraform?** [Install it here](https://www.terraform.io/downloads.html)

### 2️⃣ Configure AWS on Your Computer

Open your terminal and run:

```bash
aws configure
```

It will ask for:
- **AWS Access Key ID**: Get from your AWS console
- **AWS Secret Access Key**: Get from your AWS console  
- **Default region**: Enter `us-east-1`
- **Default output format**: Press Enter to skip

To verify it worked:
```bash
aws sts get-caller-identity
```

You should see your AWS account ID.

### 3️⃣ Add GitHub Secrets

Go to your GitHub repository:

1. Click **Settings** (top right)
2. Click **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add this secret:

| Name | Value |
|------|-------|
| `OPENAI_API_KEY` | `sk-...` (copy from https://platform.openai.com/api-keys) |

### 4️⃣ Run Automated Setup (Creates IAM Roles)

This script creates all the AWS IAM roles you need.

**On Windows:**
```bash
cd C:\path\to\ai-devops-mlops-aws
setup.bat
```

**On Mac/Linux:**
```bash
cd /path/to/ai-devops-mlops-aws
chmod +x setup.sh
./setup.sh
```

The script will:
- Ask for your GitHub username/repo name
- Ask for AWS region (default is fine)
- Create GitHub OIDC provider
- Create GitHub Actions IAM role
- Create Lambda execution IAM role
- **Show you 2 role ARNs to copy**

When it finishes, you'll see:
```
AWS_ROLE_ARN = arn:aws:iam::123456789:role/GitHubActionsRole
AWS_LAMBDA_ROLE_ARN = arn:aws:iam::123456789:role/ai-platform-lambda-role
```

### 5️⃣ Add More GitHub Secrets

Go back to GitHub Secrets (Settings → Secrets and variables → Actions):

Add these 3 more secrets with the ARNs from step 4:

| Name | Value |
|------|-------|
| `AWS_ROLE_ARN` | Paste the value from script output |
| `AWS_LAMBDA_ROLE_ARN` | Paste the value from script output |
| `AWS_REGION` | `us-east-1` |

### 6️⃣ Deploy Services (via GitHub Actions)

Go to your GitHub repository and click the **Actions** tab.

Run these workflows **in this order** (wait for each to complete):

**1. Deploy Infrastructure** (takes ~3 minutes)
   - Click the workflow name → "Run workflow" button
   - Leave environment as "prod"
   - Click "Run workflow"
   - Wait until green ✅ checkmark appears

**2. Deploy DevOps Assistant** (takes ~2 minutes)
   - Click "Run workflow" button
   - Leave environment as "prod"
   - Click "Run workflow"
   - Wait until green ✅ checkmark appears

**3. Deploy RAG Service** (takes ~2 minutes)
   - Click "Run workflow" button
   - Leave environment as "prod"
   - Click "Run workflow"
   - Wait until green ✅ checkmark appears

**4. MLOps - Train & Deploy Model** (takes ~5 minutes)
   - Click "Run workflow" button
   - Leave environment as "prod"
   - Click "Run workflow"
   - Wait until green ✅ checkmark appears

**Done!** Services are now live on AWS.

### 7️⃣ Test The Services

Go to your GitHub Actions workflow run for "Deploy DevOps Assistant". In the logs, you'll see the API URL. It looks like:

```
https://abc123.execute-api.us-east-1.amazonaws.com/prod
```

Save this URL. Test the services:

**Test 1: DevOps Assistant (AI log analyzer)**
```bash
curl -X POST https://YOUR_API_URL/analyze \
  -H "Content-Type: application/json" \
  -d '{"log": "Error: Permission denied at line 42"}'
```

You should get back an AI analysis of the error.

**Test 2: RAG Service - Upload a document**
```bash
curl -X POST https://YOUR_API_URL/upload \
  -H "Content-Type: application/json" \
  -d '{"filename": "test.txt", "content_base64": "VGhpcyBpcyBhIHRlc3QgZG9jdW1lbnQ="}'
```

**Test 3: RAG Service - Ask a question**
```bash
curl -X POST https://YOUR_API_URL/query \
  -H "Content-Type: application/json" \
  -d '{"question": "What is in the document?"}'
```

You should get back an AI answer based on the document you uploaded.

### 8️⃣ Clean Up (Stop AWS Charges)

After you're done testing, destroy everything to avoid AWS charges:

Go to **GitHub Actions** tab:
1. Click **Destroy All Infrastructure** workflow
2. Click "Run workflow"
3. Type `destroy-all` in the confirm field exactly
4. Click "Run workflow"
5. Wait for it to complete

**Result:** All AWS resources deleted, $0 charges.

---

## What Each Service Does (Detailed)

### DevOps Assistant

**Purpose:** Analyzes CI/CD logs to find problems and suggest fixes.

**How it works:**
1. You send it a build log that failed
2. It uses OpenAI GPT-4o-mini to analyze it
3. It tells you:
   - What the root cause is
   - How to fix it
   - A YAML patch to update your pipeline

**Example:**
- Input: `"Build failed: TypeError: Cannot read property 'name' of undefined"`
- Output: `"Root cause: Variable not initialized. Fix: Add config = {}"`

### RAG Service (Retrieval-Augmented Generation)

**Purpose:** Store documents and ask AI questions about them.

**How it works:**
1. You upload documents (PDF, TXT, JSON)
2. Service breaks them into chunks
3. Service creates embeddings using OpenAI
4. Service stores chunks in DynamoDB
5. When you ask a question, it:
   - Finds the most similar chunks
   - Sends them to OpenAI GPT-4o-mini
   - Returns an answer based on your documents

**Example:**
- Upload: `deployment-guide.pdf`
- Question: `"How do I deploy this?"`
- Answer: `"Based on your docs: 1) Run terraform init 2) Run terraform apply..."`

### MLOps Pipeline

**Purpose:** Trains ML models automatically.

**How it works:**
1. GitHub Actions triggers daily (at 3 AM UTC) OR when you manually trigger it
2. It trains a machine learning model
3. Saves the model to S3
4. Saves performance metrics to S3

**Where to see results:**
- AWS Console → S3 → Look for bucket starting with `ai-devops-ml-artifacts`
- Files: `model.pkl` (the trained model) and `metrics.txt` (accuracy, R², etc.)

---

## Project Structure

```
ai-devops-mlops-aws/
├── README.md                     ← You are here
├── setup.sh / setup.bat          ← Run this to create IAM roles
├── infra/
│   ├── iam-setup/
│   │   ├── main.tf              # Creates GitHub + Lambda IAM roles
│   │   └── variables.tf
│   ├── main.tf                  # Creates S3, DynamoDB, Lambda
│   ├── variables.tf
│   └── outputs.tf
├── devops_assistant/
│   ├── lambda_function.py       # AI log analyzer code
│   └── requirements.txt
├── rag_service/
│   ├── lambda_function.py       # Document search code
│   └── requirements.txt
├── mlops_pipeline/
│   ├── train.py                 # Model training code
│   └── requirements.txt
└── .github/workflows/
    ├── deploy-infra.yml
    ├── deploy-devops-assistant.yml
    ├── deploy-rag-service.yml
    ├── train-model.yml
    └── destroy-all.yml
```

---

## How Security Works

**GitHub → AWS:** 
- Uses OIDC (OpenID Connect) federation
- No AWS access keys stored in GitHub ✅
- Temporary 1-hour tokens that auto-refresh ✅
- Secure by default

**Services:**
- Lambda functions use IAM roles (minimal permissions)
- OpenAI API key encrypted in GitHub Secrets
- No secrets in code ✅

---

## Cost Estimation

| Service | Per 100 API Calls | POC (2 hours) |
|---------|------------------|---------------|
| Lambda | $0.01 | $0.002 |
| API Gateway | $0.35 | $0.07 |
| S3 | $0.001 | $0.001 |
| DynamoDB | $0.001 | $0.001 |
| OpenAI API | $0.10 | $0.02 |
| **TOTAL** | **$0.47** | **~$0.10** |

**After cleanup:** $0 (all resources deleted)

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| **Setup script fails with "aws configure not found"** | Install AWS CLI: https://aws.amazon.com/cli/ |
| **Setup script fails with "terraform not found"** | Install Terraform: https://www.terraform.io/downloads.html |
| **GitHub Actions workflow fails immediately** | Check GitHub Secrets are set (go to Settings → Secrets and variables → Actions) |
| **"Permission denied" error in workflow** | Re-run setup script: `./setup.sh` or `setup.bat` |
| **Lambda function not found error** | Run "Deploy Infrastructure" workflow first, then others |
| **"S3 bucket already exists" error** | Change bucket names in `infra/environments/prod.tfvars` |
| **API returns 502 error** | Check Lambda logs: `aws logs tail /aws/lambda/devops-assistant-prod --follow` |
| **OpenAI API error** | Verify API key is valid and has credits: `curl https://api.openai.com/v1/models -H "Authorization: Bearer YOUR_KEY"` |

---

## What If Something Goes Wrong?

**Check logs:**
1. Go to GitHub Actions → Click failing workflow run
2. Click the job name → Scroll down to see error messages
3. Look for red ❌ text

**Check AWS resources:**
```bash
# Check Lambda functions
aws lambda list-functions --region us-east-1

# Check S3 buckets
aws s3 ls

# Check DynamoDB tables
aws dynamodb list-tables --region us-east-1

# Check CloudWatch logs for Lambda errors
aws logs tail /aws/lambda/devops-assistant-prod --follow --region us-east-1
```

**If stuck:**
1. Run cleanup: `destroy-all.yml` workflow in GitHub Actions
2. Delete IAM roles manually: AWS Console → IAM → Roles
3. Start over from Step 2️⃣

---

## Next Steps

1. **Test all 3 services** using the curl commands in Step 7️⃣
2. **Upload real documents** to RAG Service and try asking questions
3. **Send CI/CD logs** to DevOps Assistant and see how it debugs them
4. **Check S3 for trained models** and review performance metrics
5. **Monitor costs** in AWS Console → Cost Explorer
6. **Clean up** using `destroy-all.yml` when done testing

---

## Architecture Overview

```
Your Computer
    ↓
    ├─ Run setup.sh/setup.bat
    │  └─ Creates IAM roles in AWS
    │
    └─ Push to GitHub
       ↓
       GitHub Actions Workflows
       ├─ deploy-infra.yml
       │  └─ Terraform creates: S3, DynamoDB, Lambda roles
       │
       ├─ deploy-devops-assistant.yml
       │  └─ Creates Lambda + API Gateway for log analysis
       │
       ├─ deploy-rag-service.yml
       │  └─ Creates Lambda + API Gateway for document Q&A
       │
       └─ train-model.yml
          └─ Trains ML model, saves to S3

Users
  ↓
  API Gateway (public endpoints)
  ├─ DevOps Assistant Lambda → OpenAI GPT-4o-mini → S3 logs
  ├─ RAG Service Lambda → OpenAI embeddings/GPT-4o-mini → DynamoDB chunks
  └─ MLOps Model → scikit-learn training → S3 artifacts
```

---

## Common Questions

**Q: Do I need AWS experience?**
A: No! This guide assumes zero AWS knowledge.

**Q: Will this cost me money?**
A: ~$0.10 for a 2-hour POC. Use `destroy-all.yml` workflow when done to delete everything.

**Q: Can I change AWS region?**
A: Yes. Update `AWS_REGION` secret in GitHub and re-run setup script.

**Q: Can I run this locally without GitHub Actions?**
A: Yes, but you'll need to configure Terraform variables manually. See `infra/environments/prod.tfvars`.

**Q: What if I lose my OpenAI API key?**
A: Get a new one from https://platform.openai.com/api-keys and update GitHub Secret.

**Q: How do I update the services?**
A: Edit the Python code (e.g., `devops_assistant/lambda_function.py`), push to GitHub, and re-run the deploy workflow.

---

## Get Help

- **GitHub Actions failing?** Check logs in GitHub Actions tab
- **AWS error?** Check CloudWatch logs: `aws logs tail /aws/lambda/FUNCTION_NAME --follow`
- **Need to debug locally?** See Lambda function code in `devops_assistant/`, `rag_service/`, `mlops_pipeline/`
- **Want to understand the architecture?** Read comments in `infra/main.tf` and Lambda function code

---

**You're ready to deploy!** Start with Step 1️⃣ above. Good luck! 🚀
