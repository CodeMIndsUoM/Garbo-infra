# Phase 0–2 Manual Setup Checklist

Complete these steps that cannot be automated from code alone.

## 1. Push DevOps branches (required)

From each app repo, push your new branch and baseline tag:

```bash
# Backend
cd Garbo_backend
git push -u origin devops/platform
git push origin pre-devops-baseline

# Web dashboard
cd Garbo_web_dashboard
git push -u origin devops/platform
git push origin pre-devops-baseline

# Flutter
cd Garbo-flutter
git push -u origin devops/platform
git push origin pre-devops-baseline
```

## 2. Create Garbo-infra on GitHub (required)

1. On GitHub (org: `CodeMIndsUoM`), create a new empty repo: `Garbo-infra`
2. From your machine:

```bash
cd Garbo-infra
git init
git add .
git commit -m "Add Phase 0-1 local compose stack and infra skeleton"
git branch -M main
git remote add origin https://github.com/CodeMIndsUoM/Garbo-infra.git
git push -u origin main
```

## 3. Backend .env for Docker (required before compose)

```bash
cd Garbo_backend
cp .env.example .env
# Fill Neon PostgreSQL + Cloudinary + JWT values
```

Ensure `SPRING_PROFILES_ACTIVE=prod` (or `local` if using local Postgres) and `SERVER_PORT=8081`.

## 4. /etc/hosts for Traefik (optional)

Add to `/etc/hosts` if you want hostname-based routing:

```
127.0.0.1 app.garbo.localhost
127.0.0.1 api.garbo.localhost
```

Direct ports `localhost:3000` and `localhost:8081` work without this.

## 5. GitHub branch protection (recommended)

In each app repo (`Garbo_backend`, `Garbo_web_dashboard`, `Garbo-flutter`), enable protection on:

- `main`
- `mergekth` (backend + web) or `mergesa` (flutter)

Settings → Branches → Add rule:

- Require pull request before merging
- Require status checks (after CI is pushed): `CI / build`

## 6. Rotate secrets if ever committed (security)

If `.env` or real credentials were ever pushed to GitHub, rotate:

- Neon database password
- Cloudinary API secret
- JWT signing secret

## 7. Test local Docker stack

```bash
cd Garbo-infra/compose
docker compose -f docker-compose.local.yml up --build
```

Verify:

- http://localhost:8081/actuator/health → `{"status":"UP"}`
- http://localhost:3000 → dashboard loads
- Login works against your Neon DB

## 8. AWS setup (Phase 3 — not started yet)

When ready for Phase 3, you will need:

- AWS account with Free Tier
- AWS CLI configured (`aws configure`)
- Terraform installed
- AWS Budget alert at $1 and $5

These are documented in `DEVOPS_ENTERPRISE_PLAN.md` Phase 3.
