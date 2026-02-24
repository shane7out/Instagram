# Las Vegas Food Curator - Deployment Guide

Complete step-by-step instructions for deploying your Instagram automation system.

---

## Overview

You'll deploy two components:
1. **Dashboard** (Streamlit Cloud) - For reviewing and approving content
2. **Bot Worker** (Railway) - For continuous content discovery

---

## Prerequisites

- GitHub account
- Railway account (railway.app)
- Streamlit Cloud account (share.streamlit.io)
- Instagram account (@lasvegas_restaurants)

---

## Step 1: Prepare Code for GitHub

### 1.1 Create GitHub Repository

1. Go to [github.com](https://github.com)
2. Click "+" → "New repository"
3. Name: `las-vegas-food-curator`
4. Make it **Public** (free)
5. Click "Create repository"

### 1.2 Upload Your Code

```bash
# Clone your repository
git clone https://github.com/YOUR_USERNAME/las-vegas-food-curator.git
cd las-vegas-food-curator

# Copy all files from lvfc_bot folder
# (upload via GitHub web interface or git commands)

# Commit and push
git add .
git commit -m "Initial commit"
git push origin main
```

---

## Step 2: Deploy Dashboard to Streamlit Cloud

### 2.1 Connect GitHub

1. Go to [share.streamlit.io](https://share.streamlit.io)
2. Sign in with GitHub
3. Click "New app"

### 2.2 Configure App

```
Repository: YOUR_USERNAME/las-vegas-food-curator
Branch: main
Main file path: lvfc_bot/dashboard.py
```

### 2.3 Add Secrets

Click "Advanced settings" → "Secrets" and add:

```toml
[secrets]
INSTAGRAM_USERNAME = "your_username"
INSTAGRAM_PASSWORD = "your_password"
```

### 2.4 Deploy

Click "Deploy". Your dashboard will be available at:
```
https://YOUR_USERNAME-las-vegas-food-curator.streamlit.app
```

---

## Step 3: Deploy Bot to Railway

### 3.1 Create Railway Project

1. Go to [railway.app](https://railway.app)
2. Sign in with GitHub
3. Click "New Project"
4. Select "Empty Project"

### 3.2 Add Variables

Go to "Variables" tab and add:

| Variable | Value |
|----------|-------|
| INSTAGRAM_USERNAME | your_username |
| INSTAGRAM_PASSWORD | your_password |
| HASHTAGS | lasvegasfood,vegaseats,lasvegasdining,vegasfoodie |
| SCAN_INTERVAL_HOURS | 6 |
| AUTO_APPROVE | false |

### 3.3 Deploy Bot Worker

1. Click "New" → "GitHub Repo"
2. Select your repository
3. Set root directory to: `lvfc_bot`
4. Click "Deploy"

### 3.4 Verify Deployment

- Check "Deployments" tab for status
- Check "Logs" for bot activity

---

## Step 4: Verify Everything Works

### 4.1 Check Dashboard

1. Open your Streamlit Cloud URL
2. Login with Instagram credentials
3. Navigate to "Content Queue"

### 4.2 Check Bot Logs

1. Open Railway dashboard
2. Go to your bot service
3. Click "Logs"
4. You should see:
   - Login success message
   - Discovery scan messages
   - New content found

---

## How It Works

### Discovery Flow

```
Railway Bot
    ↓ (every 6 hours)
Scans Instagram hashtags
    ↓
Finds food videos
    ↓
Filters by followers/engagement
    ↓
Saves to database
    ↓
Streamlit Dashboard
    ↓ (you review)
Approve → Post to Stories
```

### Daily Workflow

1. **Morning**: Check dashboard, approve pending content
2. **Railway**: Bot continues discovering new content
3. **Evening**: Review and approve more content

---

## Important Settings

### Bot Settings (Railway Variables)

| Variable | Description | Default |
|----------|-------------|---------|
| HASHTAGS | Comma-separated hashtags | lasvegasfood,vegaseats |
| SCAN_INTERVAL_HOURS | How often to scan | 6 |
| MIN_FOLLOWERS | Minimum creator followers | 1000 |
| MIN_ENGAGEMENT_RATE | Minimum engagement % | 2.0 |
| AUTO_APPROVE | Auto-post without approval | false |

### Safety Features

- Daily post limit: 50
- Rate limiting between actions
- Session persistence

---

## Troubleshooting

### Login Failed
- Check credentials in Railway variables
- Instagram may require verification - login manually first

### No Content Found
- Try different hashtags
- Increase SCAN_INTERVAL_HOURS

### Account Restricted
- Lower daily action limit
- Increase rate delay
- Don't post too frequently

---

## Cost Estimation

| Service | Plan | Monthly Cost |
|---------|------|--------------|
| Streamlit Cloud | Free | $0 |
| Railway | Hobby | $5-10 |
| **Total** | | **$5-10/month** |

---

## Security Notes

1. **Never commit** `.env` file to GitHub
2. **Use Railway secrets** for passwords
3. **Use Streamlit secrets** for dashboard credentials
4. **Monitor logs** for suspicious activity
5. **Follow Instagram ToS** to avoid bans

---

## Support

- Streamlit docs: https://docs.streamlit.io
- Railway docs: https://docs.railway.app
- instagrapi: https://github.com/subzeroid/instagrapi

---

## Next Steps

After deployment:

1. Test discovery by clicking "Run Discovery Scan"
2. Review content in "Content Queue"
3. Click "Approve" to post to Stories
4. Monitor Railway logs for activity
5. Adjust hashtags and settings as needed

---

**Enjoy automating your @lasvegas_restaurants Stories! 🍽️**
