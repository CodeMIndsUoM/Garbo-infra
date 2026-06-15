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

echo "==> ECR login"
aws ecr get-login-password --region "$REGION" \
  | docker login --username AWS --password-stdin "$ECR_REGISTRY"

echo "==> Fetch secrets from SSM"
./scripts/fetch-ssm-env.sh "$COMPOSE_DIR/.env.prod"

echo "==> Pull images (backend:$BACKEND_TAG frontend:$FRONTEND_TAG)"
docker compose -f "$COMPOSE_DIR/docker-compose.prod.yml" pull

echo "==> Start stack"
docker compose -f "$COMPOSE_DIR/docker-compose.prod.yml" up -d --remove-orphans

echo "==> Wait for backend health"
for i in $(seq 1 30); do
  if curl -sf http://localhost:8081/actuator/health >/dev/null 2>&1; then
    echo "Backend healthy"
    break
  fi
  sleep 5
done

docker compose -f "$COMPOSE_DIR/docker-compose.prod.yml" ps
echo "Deploy complete. App: http://$(curl -s http://checkip.amazonaws.com 2>/dev/null || hostname -I | awk '{print $1}')/"
