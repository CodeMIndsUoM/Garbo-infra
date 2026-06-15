#!/usr/bin/env bash
set -euo pipefail

# Run ON the EC2 server from /opt/garbo
# Usage: BACKEND_TAG=abc FRONTEND_TAG=def ./deploy.sh

cd "$(dirname "$0")/.."
COMPOSE_DIR="$(pwd)/compose"
REGION="${AWS_REGION:-ap-south-1}"
ECR_REGISTRY="${ECR_REGISTRY:?Set ECR_REGISTRY}"
BACKEND_TAG="${BACKEND_TAG:-latest}"
FRONTEND_TAG="${FRONTEND_TAG:-latest}"

export ECR_REGISTRY BACKEND_TAG FRONTEND_TAG

COMPOSE_BASE="$COMPOSE_DIR/docker-compose.prod.yml"
COMPOSE_ARGS=(-f "$COMPOSE_BASE")

if [[ -n "${GARBO_DOMAIN:-}" && -n "${ACME_EMAIL:-}" ]]; then
  export GARBO_DOMAIN ACME_EMAIL
  COMPOSE_ARGS+=(-f "$COMPOSE_DIR/docker-compose.https.yml")
  echo "==> HTTPS enabled for https://${GARBO_DOMAIN}"
else
  echo "==> HTTP only (set GARBO_DOMAIN + ACME_EMAIL in .env.deploy for HTTPS — see docs/HTTPS_SETUP.md)"
fi

echo "==> ECR login"
aws ecr get-login-password --region "$REGION" \
  | docker login --username AWS --password-stdin "$ECR_REGISTRY"

echo "==> Fetch secrets from SSM"
./scripts/fetch-ssm-env.sh "$COMPOSE_DIR/.env.prod"

echo "==> Pull images (backend:$BACKEND_TAG frontend:$FRONTEND_TAG)"
docker compose "${COMPOSE_ARGS[@]}" pull

echo "==> Start stack"
docker compose "${COMPOSE_ARGS[@]}" up -d --remove-orphans

echo "==> Wait for backend health"
for i in $(seq 1 30); do
  if curl -sf http://localhost:8081/actuator/health >/dev/null 2>&1; then
    echo "Backend healthy"
    break
  fi
  sleep 5
done

docker compose "${COMPOSE_ARGS[@]}" ps
if [[ -n "${GARBO_DOMAIN:-}" ]]; then
  echo "Deploy complete. App: https://${GARBO_DOMAIN}/"
else
  echo "Deploy complete. App: http://$(curl -s http://checkip.amazonaws.com 2>/dev/null || hostname -I | awk '{print $1}')/"
fi
