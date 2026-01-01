# GitHub Setup Guide - Dashboard Repository

This guide will help you push the SMC Dashboard repository to GitHub.

## Prerequisites

- GitHub account
- Git installed on your computer
- Both repositories committed locally

## Step 1: Create GitHub Repository

1. Go to [GitHub](https://github.com) and sign in
2. Click the **"+"** icon in the top right → **"New repository"**
3. Repository settings:
   - **Name:** `SMC_Dashboard` (or your preferred name)
   - **Description:** "Real-time web dashboard and UI/UX components for SMC Sessions EA"
   - **Visibility:** Choose Public or Private
   - **DO NOT** initialize with README, .gitignore, or license (we already have these)
4. Click **"Create repository"**

## Step 2: Add Remote and Push

Open PowerShell or Command Prompt in the Dashboard directory:

```powershell
cd "C:\Users\test\OneDrive\Desktop\Trading\all bots\SMC_Dashboard"

# Add your GitHub repository as remote (replace YOUR_USERNAME with your GitHub username)
# Based on your SMC repo, your username appears to be: Danieljacksonc33
git remote add origin https://github.com/Danieljacksonc33/SMC_Dashboard.git

# Or if using SSH:
# git remote add origin git@github.com:Danieljacksonc33/SMC_Dashboard.git

# Push to GitHub
git branch -M main
git push -u origin main
```

## Step 3: Verify

1. Go to your GitHub repository page
2. Verify all files are present:
   - `README.md`
   - `dashboard.html`
   - All `.bat` and `.ps1` files
   - `.gitignore`

## Step 4: Update SMC Repository Reference

After pushing the Dashboard repository, update the SMC repository README if needed:

1. Go to your SMC_Sessions_EA repository on GitHub
2. Update the relative path in README.md from `../SMC_Dashboard` to the actual GitHub URL:
   - `https://github.com/Danieljacksonc33/SMC_Dashboard`

Or keep the relative path if both repos are in the same organization/user account.

## Troubleshooting

### Authentication Issues

If you get authentication errors:

**Option 1: Use Personal Access Token**
1. Go to GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Generate new token with `repo` scope
3. Use token as password when pushing

**Option 2: Use GitHub CLI**
```powershell
gh auth login
```

**Option 3: Use SSH**
1. Generate SSH key: `ssh-keygen -t ed25519 -C "your_email@example.com"`
2. Add to GitHub: Settings → SSH and GPG keys → New SSH key
3. Use SSH URL for remote

### Branch Name Issues

If you get branch name errors:
```powershell
git branch -M main
```

### Push Rejected

If push is rejected:
```powershell
git pull --rebase origin main
git push -u origin main
```

## Next Steps

After pushing:
1. Add repository description on GitHub
2. Add topics/tags: `mt4`, `dashboard`, `trading`, `smc`, `expert-advisor`
3. Consider adding a LICENSE file
4. Enable GitHub Pages if you want to host the dashboard (optional)

---

**Repository Location:** `C:\Users\test\OneDrive\Desktop\Trading\all bots\SMC_Dashboard`
