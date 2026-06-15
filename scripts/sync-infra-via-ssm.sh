#!/usr/bin/env bash
set -euo pipefail

# Push compose + deploy scripts to EC2 without SSH (for GitHub Actions / garbo CLI).
# Usage:
#   EC2_INSTANCE_ID=i-0cc6c206c6c34456c ./scripts/sync-infra-via-ssm.sh

INSTANCE_ID="${EC2_INSTANCE_ID:?Set EC2_INSTANCE_ID}"
REGION="${AWS_REGION:-ap-south-1}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUNDLE_FILE="$(mktemp)"
PARAMS_FILE="$(mktemp)"
trap 'rm -f "$BUNDLE_FILE" "$PARAMS_FILE"' EXIT

tar czf "$BUNDLE_FILE" -C "$ROOT" compose scripts/deploy.sh scripts/fetch-ssm-env.sh
export BUNDLE_B64="$(base64 < "$BUNDLE_FILE" | tr -d '\n')"

echo "==> Syncing infra bundle to $INSTANCE_ID ($(wc -c < "$BUNDLE_FILE") bytes)"

python3 - <<'PY' > "$PARAMS_FILE"
import json, os
bundle = os.environ["BUNDLE_B64"]
script = (
    "bash -lc '"
    "set -euo pipefail; "
    "cd /opt/garbo; "
    f"echo {bundle} | base64 -d | tar xzf -; "
    "chmod +x scripts/*.sh; "
    "echo Infra files synced to /opt/garbo; "
    "ls -la compose/"
    "'"
)
print(json.dumps({"commands": [script]}))
PY

COMMAND_ID="$(aws ssm send-command \
  --region "$REGION" \
  --instance-ids "$INSTANCE_ID" \
  --document-name "AWS-RunShellScript" \
  --comment "Sync Garbo-infra compose files" \
  --parameters "file://${PARAMS_FILE}" \
  --query "Command.CommandId" \
  --output text)"

echo "SSM command id: $COMMAND_ID"

for i in $(seq 1 30); do
  STATUS="$(aws ssm get-command-invocation \
    --region "$REGION" \
    --command-id "$COMMAND_ID" \
    --instance-id "$INSTANCE_ID" \
    --query "Status" \
    --output text 2>/dev/null || echo "Pending")"
  echo "Sync status ($i/30): $STATUS"
  case "$STATUS" in
    Success)
      aws ssm get-command-invocation \
        --region "$REGION" \
        --command-id "$COMMAND_ID" \
        --instance-id "$INSTANCE_ID" \
        --query "StandardOutputContent" \
        --output text
      exit 0
      ;;
    Failed|Cancelled|TimedOut)
      aws ssm get-command-invocation \
        --region "$REGION" \
        --command-id "$COMMAND_ID" \
        --instance-id "$INSTANCE_ID" \
        --query "[StandardOutputContent,StandardErrorContent]" \
        --output text
      exit 1
      ;;
  esac
  sleep 5
done

echo "Sync timed out"
exit 1
