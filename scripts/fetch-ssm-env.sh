#!/usr/bin/env bash
set -euo pipefail

# Build .env.prod on EC2 from SSM Parameter Store (uses instance IAM role).
PREFIX="${SSM_PREFIX:-/garbo/prod}"
REGION="${AWS_REGION:-ap-south-1}"
OUT="${1:-.env.prod}"

get_param() {
  aws ssm get-parameter \
    --region "$REGION" \
    --name "${PREFIX}/$1" \
    --with-decryption \
    --query Parameter.Value \
    --output text
}

{
  echo "SPRING_PROFILES_ACTIVE=prod"
  echo "SERVER_PORT=8081"
  echo "PROD_SPRING_DATASOURCE_URL=$(get_param db-url)"
  echo "PROD_SPRING_DATASOURCE_USERNAME=$(get_param db-username)"
  echo "PROD_SPRING_DATASOURCE_PASSWORD=$(get_param db-password)"
  echo "PROD_SPRING_DATASOURCE_DRIVER_CLASS_NAME=org.postgresql.Driver"
  echo "CLOUDINARY_CLOUD_NAME=$(get_param cloudinary-cloud-name)"
  echo "CLOUDINARY_API_KEY=$(get_param cloudinary-api-key)"
  echo "CLOUDINARY_API_SECRET=$(get_param cloudinary-api-secret)"
  echo "GF_SECURITY_ADMIN_PASSWORD=$(get_param grafana-admin-password)"
  echo "SENTRY_DSN=$(get_param sentry-dsn)"
  if jwt=$(get_param jwt-secret 2>/dev/null) && [[ "$jwt" != "REPLACE_ME_AFTER_APPLY" ]]; then
    echo "JWT_SECRET=$jwt"
  fi
} > "$OUT"

chmod 600 "$OUT"
echo "Wrote $OUT from SSM prefix $PREFIX"
