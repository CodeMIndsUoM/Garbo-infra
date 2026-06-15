# Phase 4 — GitHub Actions Deploy (recommended)

No manual `docker build` on your Mac. GitHub runners are **linux/amd64** natively — images work on EC2.

## One-time: EC2 bootstrap (already done if you ran setup-ec2.sh)

```bash
cd Garbo-infra
EC2_HOST=13.233.77.40 SSH_KEY=~/.ssh/garbo-deploy-ke.pem ./scripts/setup-ec2.sh
```

## Step 1 — Add secrets to `Garbo-infra` repo

GitHub → **CodeMIndsUoM/Garbo-infra** → **Settings → Secrets and variables → Actions**

| Secret | Value |
|---|---|
| `AWS_ACCESS_KEY_ID` | `garbo-devops` access key |
| `AWS_SECRET_ACCESS_KEY` | `garbo-devops` secret key |
| `EC2_HOST` | `13.233.77.40` |
| `EC2_SSH_PRIVATE_KEY` | Full contents of `~/.ssh/garbo-deploy-ke.pem` |
| `NEXT_PUBLIC_API_BASE` | `http://13.233.77.40` (no `/api` suffix — the app adds `/api/...` paths) |
| `GH_PAT` | GitHub Personal Access Token (see below) |

### Create `GH_PAT` (for checkout private app repos)

1. GitHub → **Settings** (your profile) → **Developer settings** → **Personal access tokens** → **Fine-grained** or **Classic**
2. Classic: scope `repo` (full control of private repositories)
3. Copy token → paste as `GH_PAT` secret in Garbo-infra

## Step 2 — Push code to GitHub

```bash
# Garbo-infra (main)
cd Garbo-infra && git push origin main

# App repos (devops/platform) — if not pushed yet
cd Garbo_backend && git push origin devops/platform
cd Garbo_web_dashboard && git push origin devops/platform
```

## Step 3 — Run deploy workflow

1. Open **Garbo-infra** on GitHub → **Actions** tab
2. Select **Deploy Full Stack**
3. Click **Run workflow** → **Run workflow**

This will:
- Checkout `devops/platform` from backend + frontend
- Build both Docker images on **linux/amd64**
- Push to ECR (`garbo-backend`, `garbo-frontend`)
- SSH to EC2 and run `deploy.sh`

## Step 4 — Verify

- http://13.233.77.40/ — dashboard
- http://13.233.77.40/actuator/health — backend health
- http://13.233.77.40/api/... — API

## Optional: per-repo CD (incremental deploys)

Add the same AWS + EC2 secrets to `Garbo_backend` and `Garbo_web_dashboard` if you want auto-deploy on push to `devops/platform` for single-app changes.

| Repo | Workflow | When |
|---|---|---|
| **Garbo-infra** | Deploy Full Stack | Manual or push to `main` — **use this first** |
| Garbo_backend | CD | Backend-only changes |
| Garbo_web_dashboard | CD | Frontend-only changes |

## JWT secret

Add later in SSM: `/garbo/prod/jwt-secret`. Login will fail until then.
