# Garbo Infrastructure

Shared DevOps assets for the Garbo Waste Management System.

This repo holds infrastructure-as-code, Docker Compose stacks, deployment scripts, and runbooks. Application code stays in the app repos.

## Repositories

| Repo | Team branch | DevOps branch |
|---|---|---|
| `Garbo_backend` | `mergekth` | `devops/platform` |
| `Garbo_web_dashboard` | `mergekth` | `devops/platform` |
| `Garbo-flutter` | `mergesa` | `devops/platform` |
| `Garbo-infra` (this repo) | — | `main` |

## Local Docker stack (Phase 1)

### Prerequisites

1. Docker Desktop (or Docker Engine + Compose plugin)
2. `Garbo_backend/.env` exists (copy from `.env.example` and fill Neon + Cloudinary credentials)
3. Optional Traefik hostnames in `/etc/hosts`:

```
127.0.0.1 app.garbo.localhost
127.0.0.1 api.garbo.localhost
```

### Start

```bash
cd compose
cp .env.example .env   # adjust paths if your repos are elsewhere
docker compose -f docker-compose.local.yml up --build
```

### URLs

| Service | Direct | Via Traefik |
|---|---|---|
| Dashboard | http://localhost:3000 | http://app.garbo.localhost |
| Backend API | http://localhost:8081 | http://api.garbo.localhost |
| Health check | http://localhost:8081/actuator/health | — |

### Stop

```bash
docker compose -f docker-compose.local.yml down
```

## Directory layout

```
Garbo-infra/
├── compose/           # Docker Compose stacks
├── terraform/         # AWS IaC (Phase 3)
├── ansible/           # Host bootstrap (Phase 3)
├── monitoring/        # Observability stack (Phase 5)
├── scripts/           # Deploy and ops scripts
└── docs/              # Runbooks
```
