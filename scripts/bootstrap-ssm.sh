#!/usr/bin/env bash
set -euo pipefail

# Seed SSM SecureString parameters from Garbo_backend/.env
# Run AFTER: terraform apply
#
# Usage:
#   ./scripts/bootstrap-ssm.sh ../../Garbo_backend/.env

ENV_FILE="${1:-../../Garbo_backend/.env}"
PREFIX="/garbo/prod"
REGION="${AWS_REGION:-ap-south-1}"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Env file not found: $ENV_FILE"
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

put_param() {
  local name="$1"
  local value="$2"
  aws ssm put-parameter \
    --region "$REGION" \
    --name "${PREFIX}/${name}" \
    --type SecureString \
    --overwrite \
    --value "$value" >/dev/null
  echo "Updated ${PREFIX}/${name}"
}

put_param "db-url" "${PROD_SPRING_DATASOURCE_URL:-}"
put_param "db-username" "${PROD_SPRING_DATASOURCE_USERNAME:-}"
put_param "db-password" "${PROD_SPRING_DATASOURCE_PASSWORD:-}"
put_param "cloudinary-cloud-name" "${CLOUDINARY_CLOUD_NAME:-}"
put_param "cloudinary-api-key" "${CLOUDINARY_API_KEY:-}"
put_param "cloudinary-api-secret" "${CLOUDINARY_API_SECRET:-}"

if [[ -n "${JWT_SECRET:-}" ]]; then
  put_param "jwt-secret" "$JWT_SECRET"
else
  echo "WARN: JWT_SECRET not in .env — set /garbo/prod/jwt-secret manually in AWS Console"
fi

echo "Done. Verify with: aws ssm get-parameter --name ${PREFIX}/db-url --with-decryption --region ${REGION}"
