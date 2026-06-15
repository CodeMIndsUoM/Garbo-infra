# Phase 3 — Terraform (AWS)

Provisions a **new** Garbo app server on AWS Free Tier. Does not touch your current manual deployment.

## What gets created

- VPC + public subnet + security group (SSH locked to your IP, 80/443 open)
- EC2 `t3.micro` with Docker pre-installed
- ECR repos: `garbo-backend`, `garbo-frontend`
- SSM Parameter Store placeholders for secrets
- CloudWatch log groups + CPU alarm

## Prerequisites

Already verified on your machine:

- AWS CLI configured (`aws sts get-caller-identity` works)
- Terraform installed
- An existing EC2 key pair in the same region

## One-time setup

```bash
cd terraform/envs/prod
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars:
#   - ssh_allowed_cidr = "YOUR_PUBLIC_IP/32"
#   - key_name = your EC2 key pair name
```

## Deploy infrastructure

```bash
cd terraform/envs/prod
terraform init
terraform plan
terraform apply
```

## After apply — seed secrets

```bash
chmod +x ../../../scripts/bootstrap-ssm.sh
../../../scripts/bootstrap-ssm.sh ../../../../Garbo_backend/.env
```

## Destroy (stops billing)

```bash
terraform destroy
```

## Your current AWS connection

| Item | Value |
|---|---|
| Account | `392202704441` |
| IAM user | `datastrom_model` |
| Region | `ap-south-1` |
| Key pairs found | `proxymaze-key`, `insightai-deploy-key` |

Update `ssh_allowed_cidr` whenever your home IP changes.
