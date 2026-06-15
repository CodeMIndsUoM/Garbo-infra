#!/usr/bin/env bash
set -euo pipefail

# One-time bootstrap: copy Garbo-infra files to EC2 and install AWS CLI.
# Run from your Mac:
#   EC2_HOST=13.233.77.40 SSH_KEY=~/.ssh/garbo-deploy-ke.pem ./scripts/setup-ec2.sh

EC2_HOST="${EC2_HOST:?Set EC2_HOST}"
SSH_KEY="${SSH_KEY:-$HOME/.ssh/garbo-deploy-ke.pem}"
ECR_REGISTRY="${ECR_REGISTRY:-392202704441.dkr.ecr.ap-south-1.amazonaws.com}"
REMOTE_DIR="/opt/garbo"

SSH_OPTS=(-i "$SSH_KEY" -o StrictHostKeyChecking=no)

echo "==> Prepare remote directory"
ssh "${SSH_OPTS[@]}" "ubuntu@$EC2_HOST" "sudo mkdir -p $REMOTE_DIR && sudo chown ubuntu:ubuntu $REMOTE_DIR"

echo "==> Copy compose + scripts"
rsync -avz -e "ssh ${SSH_OPTS[*]}" \
  --exclude '.git' \
  "$(dirname "$0")/../compose/" "ubuntu@$EC2_HOST:$REMOTE_DIR/compose/"

rsync -avz -e "ssh ${SSH_OPTS[*]}" \
  "$(dirname "$0")/" "ubuntu@$EC2_HOST:$REMOTE_DIR/scripts/"

ssh "${SSH_OPTS[@]}" "ubuntu@$EC2_HOST" "chmod +x $REMOTE_DIR/scripts/*.sh"

echo "==> Install AWS CLI v2 if missing"
ssh "${SSH_OPTS[@]}" "ubuntu@$EC2_HOST" bash -s <<'REMOTE'
if ! command -v aws >/dev/null; then
  sudo apt-get update -qq
  sudo apt-get install -y -qq unzip curl
  curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
  unzip -qo /tmp/awscliv2.zip -d /tmp
  sudo /tmp/aws/install
fi
aws --version
REMOTE

echo "==> Write environment defaults"
ssh "${SSH_OPTS[@]}" "ubuntu@$EC2_HOST" bash -s <<REMOTE
cat > $REMOTE_DIR/.env.deploy <<EOF
ECR_REGISTRY=$ECR_REGISTRY
AWS_REGION=ap-south-1
SSM_PREFIX=/garbo/prod
EOF
REMOTE

echo "Setup complete. SSH: ssh -i $SSH_KEY ubuntu@$EC2_HOST"
echo "Deploy: ssh ... 'cd $REMOTE_DIR && set -a && source .env.deploy && set +a && BACKEND_TAG=latest FRONTEND_TAG=latest ./scripts/deploy.sh'"
