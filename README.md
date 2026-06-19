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
docker compose -f docker-compose.local.yml up --build
```

**Note:** `Garbo_backend/.env` has both local (`SPRING_DATASOURCE_URL=localhost`) and Neon (`PROD_SPRING_DATASOURCE_*`) values. The backend container maps `PROD_*` → `SPRING_DATASOURCE_*` at startup so Docker uses Neon automatically.

### URLs (Local Stack)

| Service | Direct | Via Traefik |
|---|---|---|
| Dashboard | http://localhost:3000 | http://app.garbo.localhost |
| Backend API | http://localhost:8081 | http://api.garbo.localhost |
| Health check | http://localhost:8081/actuator/health | — |

### Production Monitoring Stack

In production, the following observability services are configured in the compose stack (`docker-compose.prod.yml` & `docker-compose.https.yml`):

* **Prometheus**: Runs internally on port `9090`. Scrapes host metrics from `node-exporter` and JVM metrics from `/actuator/prometheus` at 15s intervals.
* **Node Exporter**: Runs on port `9100`. Exposes host resource utilization (CPU, RAM, Disk, Net) safely to Prometheus.
* **Grafana**: Routed securely under `https://garboadmin.duckdns.org/grafana`.
  * **Configuration**: Credentials and variables are retrieved from AWS Parameter Store via `scripts/fetch-ssm-env.sh` (`/garbo/prod/grafana-admin-password`).
  * **SQLite Database Persistence**: Mapped to named Docker volume `grafana-data` to preserve imported dashboards (such as Node Exporter ID `1860` and JVM ID `4701`) across updates.

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
