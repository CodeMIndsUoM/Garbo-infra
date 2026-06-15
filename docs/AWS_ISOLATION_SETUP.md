# Garbo AWS — Separate from Your Earlier Project

Your earlier project uses:
- IAM user: `datastrom_model`
- Account: `392202704441`
- Old EC2 + key pairs (`insightai-deploy-key`, `proxymaze-key`)

**Garbo must be isolated** — new EC2, new IAM user, new SSH key. Do **not** reuse the old project's credentials or key pairs.

---

## 1. Instance recommendation for Garbo (OR-Tools + Spring Boot)

| Instance | vCPU | RAM | Free Tier? | Verdict |
|---|---|---|---|---|
| `t3.micro` | 2 | 1 GB | Yes (750 hrs/mo) | Too small — OR-Tools will OOM |
| `t3.small` | 2 | 2 GB | No | Still tight |
| **`t3.medium`** | 2 | **4 GB** | No | **Minimum for Garbo** |
| **`t3.large`** | 2 | **8 GB** | No | **Recommended** if route optimization is heavy |

**Recommendation:** Start with **`t3.medium`** (~$30/month in `ap-south-1` if running 24/7). Upgrade to `t3.large` if route optimization still struggles.

Free Tier only covers **one `t3.micro` 24/7**. Garbo needs more RAM — accept the cost or run the server only when demoing (stop instance when not in use).

---

## 2. Create a NEW IAM user for Garbo only

Do this in **AWS Console → IAM → Users → Create user**.

| Field | Value |
|---|---|
| User name | `garbo-devops` |
| Access type | Programmatic access (Access key) |

Attach a **custom policy** (not AdministratorAccess). Copy from `docs/garbo-devops-policy.json` or paste below:

> **If `terraform apply` fails with `iam:CreateRole AccessDenied`**, your `garbo-devops` user is missing IAM permissions. Log into AWS Console as **root or admin** (not garbo-devops), open IAM → Users → garbo-devops → Add permissions → Attach `GarboDevOpsPolicy` (or create policy from `docs/garbo-devops-policy.json`), then re-run `terraform apply`.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "GarboTerraform",
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "iam:CreateRole",
        "iam:DeleteRole",
        "iam:GetRole",
        "iam:PassRole",
        "iam:AttachRolePolicy",
        "iam:DetachRolePolicy",
        "iam:PutRolePolicy",
        "iam:DeleteRolePolicy",
        "iam:GetRolePolicy",
        "iam:ListRolePolicies",
        "iam:ListAttachedRolePolicies",
        "iam:CreateInstanceProfile",
        "iam:DeleteInstanceProfile",
        "iam:GetInstanceProfile",
        "iam:AddRoleToInstanceProfile",
        "iam:RemoveRoleFromInstanceProfile",
        "iam:ListInstanceProfilesForRole",
        "iam:TagRole",
        "iam:TagInstanceProfile",
        "ecr:*",
        "ssm:*",
        "logs:*",
        "cloudwatch:*"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": "ap-south-1"
        }
      }
    }
  ]
}
```

Save the **Access Key ID** and **Secret Access Key** — shown only once.

---

## 3. Configure terminal for Garbo (separate AWS profile)

Do **not** overwrite your old project's credentials. Use a named profile:

```bash
aws configure --profile garbo
# Access Key ID:     <garbo-devops key>
# Secret Access Key: <garbo-devops secret>
# Region:            ap-south-1
# Output:            json
```

Verify:

```bash
aws sts get-caller-identity --profile garbo
# Should show: arn:aws:iam::392202704441:user/garbo-devops
```

Run Terraform with Garbo profile only:

```bash
export AWS_PROFILE=garbo
cd Garbo-infra/terraform/envs/prod
terraform plan
terraform apply
```

Your old `datastrom_model` profile stays untouched for the earlier project.

---

## 4. Create a NEW EC2 key pair for Garbo

**AWS Console → EC2 → Key Pairs → Create key pair**

| Field | Value |
|---|---|
| Name | `garbo-deploy-key` |
| Type | RSA |
| Format | `.pem` |

Download `garbo-deploy-key.pem` and store it safely:

```bash
mv ~/Downloads/garbo-deploy-key.pem ~/.ssh/
chmod 400 ~/.ssh/garbo-deploy-key.pem
```

Update `terraform/envs/prod/terraform.tfvars`:

```
key_name = "garbo-deploy-key"
```

**Do not use** `insightai-deploy-key` or `proxymaze-key` — those belong to your earlier project.

---

## 5. Update your SSH IP (may differ from old project)

Get your **current** public IP:

```bash
curl https://checkip.amazonaws.com
```

Update `terraform.tfvars`:

```
ssh_allowed_cidr = "YOUR_CURRENT_IP/32"
```

---

## 6. How to revoke / separate the earlier project

### What Garbo Terraform does NOT touch

Terraform creates **only new resources** tagged `Project=garbo`:
- New VPC (`garbo-vpc`)
- New EC2 (`garbo-app`)
- New security group, ECR repos, SSM params

It does **not** modify or delete your old EC2 unless you explicitly import it into Terraform state.

### Revoke old IAM user access (optional, when ready)

If you no longer need `datastrom_model` for the earlier project:

1. **IAM → Users → datastrom_model → Security credentials**
2. **Deactivate** or **Delete** access keys (not the user itself if the old project still needs it)
3. Or attach a tighter policy that excludes Garbo-tagged resources

### Revoke SSH access to old EC2 (optional)

On the **old EC2 security group** (AWS Console → EC2 → Security Groups):
- Remove your IP from port 22 inbound rules, or
- Stop/terminate the old instance if the earlier project is finished

### Keep projects separate going forward

| Item | Earlier project | Garbo project |
|---|---|---|
| IAM user | `datastrom_model` | `garbo-devops` |
| AWS CLI profile | default | `garbo` |
| SSH key | `insightai-deploy-key` | `garbo-deploy-key` |
| EC2 | old instance | new `garbo-app` (Terraform) |
| Terraform state | (none or separate) | `Garbo-infra/terraform/envs/prod/` |

---

## 7. Updated terraform.tfvars for Garbo

```hcl
aws_region           = "ap-south-1"
project_name         = "garbo"
environment          = "prod"
instance_type        = "t3.medium"      # or t3.large
key_name             = "garbo-deploy-key"
ssh_allowed_cidr     = "YOUR_IP/32"
ssm_parameter_prefix = "/garbo/prod"
```

---

## 8. Deploy when ready

```bash
export AWS_PROFILE=garbo
cd Garbo-infra/terraform/envs/prod
terraform init
terraform plan    # should show 24 NEW resources, 0 changes to existing
terraform apply
```

After apply:

```bash
../../../scripts/bootstrap-ssm.sh ../../../../Garbo_backend/.env
ssh -i ~/.ssh/garbo-deploy-key.pem ubuntu@<EC2_PUBLIC_IP>
```

---

## 9. Stop billing when not using Garbo

```bash
export AWS_PROFILE=garbo
# Stop instance (keeps disk, no compute charge)
aws ec2 stop-instances --instance-ids <INSTANCE_ID>

# Or destroy everything Garbo created
cd Garbo-infra/terraform/envs/prod
terraform destroy
```

---

## Checklist before `terraform apply`

- [ ] Created IAM user `garbo-devops` with new access keys
- [ ] Ran `aws configure --profile garbo`
- [ ] Created key pair `garbo-deploy-key` and saved `.pem`
- [ ] Updated `terraform.tfvars` (instance type, key name, your IP)
- [ ] Verified `aws sts get-caller-identity --profile garbo` shows `garbo-devops`
- [ ] Confirmed `terraform plan` shows only **add** (24 resources), no **destroy** on old resources
