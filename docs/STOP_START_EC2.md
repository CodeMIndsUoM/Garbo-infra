# Stop / start EC2 (with Elastic IP)

Garbo prod uses a **stable Elastic IP** so stop/start does not change the public address.

## Current stable IP

After `terraform apply` (Elastic IP module):

```bash
cd Garbo-infra/terraform/envs/prod
AWS_PROFILE=garbo terraform output ec2_public_ip
```

Update **DuckDNS once** if the IP changed: `garboadmin.duckdns.org` → that output value.

## Stop (save compute cost)

1. AWS Console → EC2 → `garbo-app` → **Instance state** → **Stop instance**
2. Do **not** use "Skip OS shutdown" unless emergency
3. Do **not** **Terminate**

While stopped:
- No EC2 compute charge
- EBS disk still billed (small)
- Elastic IP stays attached (small charge while stopped — normal for fixed IP)

## Start again

1. EC2 → **Start instance**
2. Wait 2–3 minutes
3. Public IP is **unchanged** (Elastic IP)
4. Docker containers use `restart: unless-stopped` — stack should come back automatically

Verify:

```bash
curl -sf https://garboadmin.duckdns.org/actuator/health
```

If containers did not start:

```bash
ssh -i ~/.ssh/garbo-deploy-ke.pem ubuntu@$(terraform output -raw ec2_public_ip)
cd /opt/garbo && set -a && source .env.deploy && set +a
BACKEND_TAG=latest FRONTEND_TAG=latest ./scripts/deploy.sh
```

## What you do NOT need after stop/start

- DuckDNS update (same Elastic IP)
- GitHub secrets change
- Flutter `API_BASE` change
- Re-run Terraform (unless you destroyed infra)
