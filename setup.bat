@echo off
REM ============================================================================
REM AI DevOps MLOps AWS - Automated Setup Script (Windows)
REM ============================================================================
REM This script automates the IAM role creation via Terraform
REM Run this once before deploying services via GitHub Actions
REM ============================================================================

setlocal enabledelayedexpansion

echo.
echo 🚀 AI DevOps MLOps AWS - Automated Setup
echo ==========================================
echo.

REM Check prerequisites
echo 📋 Checking prerequisites...

where terraform >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Terraform not found. Please install Terraform first:
    echo    https://www.terraform.io/downloads.html
    exit /b 1
)

where aws >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ❌ AWS CLI not found. Please install AWS CLI first:
    echo    https://aws.amazon.com/cli/
    exit /b 1
)

for /f "tokens=*" %%i in ('aws sts get-caller-identity --query Account --output text 2^>nul') do set AWS_ACCOUNT_ID=%%i

if "!AWS_ACCOUNT_ID!"=="" (
    echo ❌ AWS credentials not configured. Run 'aws configure' first
    exit /b 1
)

echo ✅ All prerequisites found
echo.

REM Get GitHub credentials
echo 📝 GitHub Configuration
set /p GITHUB_ORG="Enter GitHub organization/username [murtalabello]: "
if "!GITHUB_ORG!"=="" set GITHUB_ORG=murtalabello

set /p GITHUB_REPO="Enter GitHub repository name [ai-devops-mlops-aws]: "
if "!GITHUB_REPO!"=="" set GITHUB_REPO=ai-devops-mlops-aws

echo.
echo 🔐 AWS Configuration
set /p AWS_REGION="Enter AWS region [us-east-1]: "
if "!AWS_REGION!"=="" set AWS_REGION=us-east-1

echo.
echo ==========================================
echo Configuration Summary:
echo   AWS Account ID: !AWS_ACCOUNT_ID!
echo   AWS Region: !AWS_REGION!
echo   GitHub Org: !GITHUB_ORG!
echo   GitHub Repo: !GITHUB_REPO!
echo ==========================================
echo.

REM Navigate to IAM setup directory
cd /d "%~dp0infra\iam-setup" || exit /b 1

echo 🔧 Setting up IAM roles via Terraform...
echo.

REM Initialize Terraform
echo 📦 Initializing Terraform...
call terraform init -no-color
if %ERRORLEVEL% NEQ 0 exit /b 1

REM Plan (for review)
echo 📋 Planning Terraform changes...
call terraform plan -no-color ^
  -var="aws_region=!AWS_REGION!" ^
  -var="github_org=!GITHUB_ORG!" ^
  -var="github_repo=!GITHUB_REPO!" ^
  -out=tfplan
if %ERRORLEVEL% NEQ 0 exit /b 1

echo.
echo ==========================================
set /p PROCEED="Review the plan above. Proceed? (yes/no): "

if /i "!PROCEED!" NEQ "yes" (
    echo Cancelled. Run this script again to retry.
    del /f tfplan 2>nul
    exit /b 0
)

REM Apply
echo.
echo 🚀 Applying Terraform configuration...
call terraform apply -no-color tfplan
if %ERRORLEVEL% NEQ 0 exit /b 1
del /f tfplan 2>nul

echo.
echo ==========================================
echo ✅ IAM Roles Created Successfully!
echo ==========================================
echo.

REM Get outputs
echo 📤 Retrieving role ARNs...
for /f "tokens=*" %%i in ('terraform output -raw github_actions_role_arn') do set GITHUB_ROLE_ARN=%%i
for /f "tokens=*" %%i in ('terraform output -raw lambda_execution_role_arn') do set LAMBDA_ROLE_ARN=%%i

echo.
echo ==========================================
echo 🔐 Add these to GitHub Secrets:
echo ==========================================
echo.
echo 1. Go to: https://github.com/!GITHUB_ORG!/!GITHUB_REPO!/settings/secrets/actions
echo.
echo 2. Add these secrets:
echo.
echo    Name: AWS_ROLE_ARN
echo    Value: !GITHUB_ROLE_ARN!
echo.
echo    Name: AWS_LAMBDA_ROLE_ARN
echo    Value: !LAMBDA_ROLE_ARN!
echo.
echo    Name: AWS_REGION
echo    Value: !AWS_REGION!
echo.
echo    Name: OPENAI_API_KEY
echo    Value: sk-... (from https://platform.openai.com/api-keys)
echo.
echo ==========================================
echo.
echo ✨ Next Steps:
echo    1. ✅ Added GitHub Secrets (above)
echo    2. 🚀 Go to GitHub Actions and run: Deploy Infrastructure
echo    3. 🚀 Then run: Deploy DevOps Assistant
echo    4. 🚀 Then run: Deploy RAG Service
echo    5. 🚀 Then run: MLOps - Train and Deploy Model
echo.
echo See START_HERE.md for complete documentation
echo.

pause
