# HTTPS setup (Traefik + Let's Encrypt)

Production today: **HTTP on IP** (`http://13.233.77.40`).

This guide enables **HTTPS on your own domain** with a free Let's Encrypt certificate. Until you have a domain, keep using the IP — the HTTPS overlay is optional.

## Prerequisites

| Item | Example |
|------|---------|
| Domain you control | `garbo.yourname.com` |
| DNS A record | Points to `13.233.77.40` |
| Email for Let's Encrypt | `you@gmail.com` |
| Port 443 open | Already configured in Terraform security group |

## Step 1 — Point DNS to EC2

At your domain registrar (Namecheap, GoDaddy, Cloudflare, etc.):

| Type | Name | Value | TTL |
|------|------|-------|-----|
| A | `@` or `garbo` | `13.233.77.40` | 300 |

Wait 5–30 minutes, then verify:

```bash
dig +short garbo.yourname.com
# Should print: 13.233.77.40
```

## Step 2 — Enable HTTPS on EC2

SSH to the server (or use SSM Session Manager):

```bash
ssh -i ~/.ssh/garbo-deploy-ke.pem ubuntu@13.233.77.40
```

Edit `/opt/garbo/.env.deploy`:

```bash
nano /opt/garbo/.env.deploy
```

Add (replace with your values):

```env
GARBO_DOMAIN=garbo.yourname.com
ACME_EMAIL=you@gmail.com
```

Save and deploy:

```bash
cd /opt/garbo
set -a && source .env.deploy && set +a
BACKEND_TAG=latest FRONTEND_TAG=latest ./scripts/deploy.sh
```

Traefik will request a certificate on first HTTPS request (HTTP-01 challenge on port 80).

## Step 3 — Sync latest compose files (if needed)

From your Mac, after pulling latest `Garbo-infra`:

```bash
cd Garbo-infra
EC2_HOST=13.233.77.40 SSH_KEY=~/.ssh/garbo-deploy-ke.pem ./scripts/setup-ec2.sh
```

Or from CI / CLI (no SSH):

```bash
EC2_INSTANCE_ID=i-0cc6c206c6c34456c ./scripts/sync-infra-via-ssm.sh
```

## Step 4 — Update app URLs

### Web dashboard (GitHub secret)

In **Garbo_web_dashboard** → Settings → Secrets:

| Secret | New value |
|--------|-----------|
| `NEXT_PUBLIC_API_BASE` | `https://garbo.yourname.com` (no `/api`) |

Redeploy frontend (push to `devops/platform` or run CD workflow).

Also update in **Garbo-infra** if you use full-stack deploy.

### Flutter APK

Edit `Garbo-flutter/.github/workflows/build-apk.yml`:

```yaml
env:
  API_BASE: https://garbo.yourname.com/api
```

Push to `devops/platform` to rebuild the APK.

### Android cleartext

HTTPS does not need `usesCleartextTraffic` changes. Your manifest already allows HTTP for dev; HTTPS works out of the box.

## Step 5 — Verify

```bash
curl -I https://garbo.yourname.com/
curl -sf https://garbo.yourname.com/actuator/health
```

Browser: open `https://garbo.yourname.com` — padlock should show.

Test login on web and mobile with the new HTTPS URLs.

## How it works

```
Browser ──HTTPS:443──► Traefik (Let's Encrypt cert)
                          ├── /api, /ws, /actuator → backend:8081
                          └── /                    → frontend:3000

Browser ──HTTP:80──► IP 13.233.77.40  (still works — migration fallback)
Browser ──HTTP:80──► domain            → 301 redirect to HTTPS
```

- `docker-compose.prod.yml` — base stack, IP + path routing on port 80
- `docker-compose.https.yml` — overlay when `GARBO_DOMAIN` + `ACME_EMAIL` are set
- Certificate stored in Docker volume `traefik-letsencrypt` (auto-renewed by Traefik)

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Certificate not issued | Confirm DNS points to EC2; port 80 must be reachable (Let's Encrypt HTTP challenge) |
| `404` on domain | Re-run deploy after setting `GARBO_DOMAIN`; check `docker compose ps` |
| Login works on IP but not HTTPS | Update `NEXT_PUBLIC_API_BASE` and rebuild frontend |
| Mobile app fails | Rebuild APK with `https://...` API_BASE |
| Mixed content errors | Frontend must use `https://` API base, not `http://` |

## Rollback

Remove `GARBO_DOMAIN` and `ACME_EMAIL` from `.env.deploy`, redeploy — back to HTTP-only on IP.
