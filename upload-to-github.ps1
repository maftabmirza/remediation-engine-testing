# upload-to-github.ps1
# PowerShell script to upload testing repository to GitHub

Write-Host "=== Uploading to GitHub: remediation-engine-testing ===" -ForegroundColor Green
Write-Host ""

# Configuration
$REPO_URL = "https://github.com/maftabmirza/remediation-engine-testing.git"
$REPO_NAME = "remediation-engine-testing"

# Check if git is installed
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: Git is not installed. Please install Git first." -ForegroundColor Red
    Write-Host "Download from: https://git-scm.com/download/win"
    exit 1
}

Write-Host "✓ Git found: $(git --version)" -ForegroundColor Green

# Get current directory
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
Write-Host "Working directory: $SCRIPT_DIR" -ForegroundColor Yellow
Write-Host ""

# Check if already a git repository
if (Test-Path ".git") {
    Write-Host "Git repository already initialized." -ForegroundColor Yellow
    
    $response = Read-Host "Do you want to reinitialize? (y/N)"
    if ($response -eq 'y' -or $response -eq 'Y') {
        Remove-Item -Path ".git" -Recurse -Force
        Write-Host "Removed existing .git directory" -ForegroundColor Yellow
    }
}

# Initialize git repository
if (-not (Test-Path ".git")) {
    Write-Host "Initializing Git repository..." -ForegroundColor Cyan
    git init
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Git repository initialized" -ForegroundColor Green
    }
    else {
        Write-Host "ERROR: Failed to initialize git repository" -ForegroundColor Red
        exit 1
    }
}

# Create .gitignore if it doesn't exist
if (-not (Test-Path ".gitignore")) {
    Write-Host "WARNING: .gitignore not found. Creating one..." -ForegroundColor Yellow
    @"
__pycache__/
*.pyc
.venv/
venv/
reports/
.pytest_cache/
.env
*.log
"@ | Out-File -FilePath ".gitignore" -Encoding UTF8
}

# Configure git user if not set
$gitUserName = git config user.name
$gitUserEmail = git config user.email

if ([string]::IsNullOrEmpty($gitUserName)) {
    Write-Host ""
    Write-Host "Git user name not configured." -ForegroundColor Yellow
    $userName = Read-Host "Enter your name (for git commits)"
    git config user.name "$userName"
}

if ([string]::IsNullOrEmpty($gitUserEmail)) {
    Write-Host ""
    Write-Host "Git user email not configured." -ForegroundColor Yellow
    $userEmail = Read-Host "Enter your email (for git commits)"
    git config user.email "$userEmail"
}

Write-Host ""
Write-Host "Git user: $(git config user.name) <$(git config user.email)>" -ForegroundColor Cyan

# Stage all files
Write-Host ""
Write-Host "Staging files..." -ForegroundColor Cyan
git add .

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Files staged" -ForegroundColor Green
}
else {
    Write-Host "ERROR: Failed to stage files" -ForegroundColor Red
    exit 1
}

# Show status
Write-Host ""
Write-Host "Files to be committed:" -ForegroundColor Cyan
git status --short

# Commit
Write-Host ""
$commitMessage = Read-Host "Enter commit message (default: 'Initial commit: IaC testing infrastructure')"
if ([string]::IsNullOrEmpty($commitMessage)) {
    $commitMessage = "Initial commit: IaC testing infrastructure"
}

git commit -m "$commitMessage"

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Changes committed" -ForegroundColor Green
}
else {
    Write-Host "ERROR: Failed to commit changes" -ForegroundColor Red
    exit 1
}

# Set branch to main
Write-Host ""
Write-Host "Setting branch to 'main'..." -ForegroundColor Cyan
git branch -M main
Write-Host "✓ Branch set to main" -ForegroundColor Green

# Add remote
Write-Host ""
Write-Host "Adding remote repository..." -ForegroundColor Cyan
Write-Host "URL: $REPO_URL" -ForegroundColor Yellow

# Remove existing remote if it exists
git remote remove origin 2>$null

git remote add origin $REPO_URL

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Remote added" -ForegroundColor Green
}
else {
    Write-Host "ERROR: Failed to add remote" -ForegroundColor Red
    exit 1
}

# Push to GitHub
Write-Host ""
Write-Host "=== Ready to Push to GitHub ===" -ForegroundColor Green
Write-Host ""
Write-Host "IMPORTANT: You will be prompted for GitHub credentials" -ForegroundColor Yellow
Write-Host "If you have 2FA enabled, use a Personal Access Token instead of password" -ForegroundColor Yellow
Write-Host ""
Write-Host "To create a token:" -ForegroundColor Cyan
Write-Host "  1. Go to: https://github.com/settings/tokens" -ForegroundColor Cyan
Write-Host "  2. Click 'Generate new token (classic)'" -ForegroundColor Cyan
Write-Host "  3. Select 'repo' scope" -ForegroundColor Cyan
Write-Host "  4. Generate and copy the token" -ForegroundColor Cyan
Write-Host "  5. Use token as password when prompted" -ForegroundColor Cyan
Write-Host ""

$response = Read-Host "Continue with push? (Y/n)"
if ($response -eq 'n' -or $response -eq 'N') {
    Write-Host "Push cancelled. You can push later with: git push -u origin main" -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "Pushing to GitHub..." -ForegroundColor Cyan
git push -u origin main

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "=== ✓ Successfully Pushed to GitHub! ===" -ForegroundColor Green
    Write-Host ""
    Write-Host "Repository URL: https://github.com/maftabmirza/$REPO_NAME" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "  1. View repo: https://github.com/maftabmirza/$REPO_NAME" -ForegroundColor White
    Write-Host "  2. Enable GitHub Actions (if not automatic)" -ForegroundColor White
    Write-Host "  3. Deploy to test server: .\scripts\deploy-to-server.sh" -ForegroundColor White
    Write-Host ""
}
else {
    Write-Host ""
    Write-Host "ERROR: Failed to push to GitHub" -ForegroundColor Red
    Write-Host ""
    Write-Host "Common issues:" -ForegroundColor Yellow
    Write-Host "  • Wrong credentials - Try using Personal Access Token" -ForegroundColor White
    Write-Host "  • Repository doesn't exist - Create it on GitHub first" -ForegroundColor White
    Write-Host "  • Network issues - Check internet connection" -ForegroundColor White
    Write-Host ""
    Write-Host "Retry with: git push -u origin main" -ForegroundColor Cyan
    exit 1
}
