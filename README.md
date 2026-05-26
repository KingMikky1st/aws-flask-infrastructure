# AWS Flask Infrastructure

Multi-tier AWS infrastructure for a Flask app, managed with Terraform.
Built as a learning project while studying for the AWS Solutions Architect exam.

## Architecture

VPC with public/private subnets across 2 availability zones. The load 
balancer and EC2 instance sit in public subnets, RDS lives in private 
subnets with no internet route.
```
Internet → ALB → EC2 (Flask) → RDS (PostgreSQL)
```

## What's in here

- `terraform/main.tf` — VPC, subnets, security groups, IGW, route tables
- `terraform/modules/vpc/` — pulled VPC config into a module so it's reusable
- `scripts/validate_infrastructure.py` — Boto3 script that checks all 
   components are running after deployment

## Deploy
```bash
cd terraform
terraform init
terraform plan
terraform apply
```

Takes about 10-15 minutes. Get the app URL with:
```bash
terraform output load_balancer_url
```

## Tear down
```bash
terraform destroy
```

**Monthly cost for 24/7 operation:**

| Service | Instance Type | Monthly Cost |
|---------|---------------|--------------|
| EC2 | t2.micro | ~$8.50 |
| RDS | db.t3.micro | ~$15 |
| ALB | Application LB | ~$16 |
| S3 | Standard storage | ~$1 |
| **Total** | | **~$40-45/month** |

Costs ~$40-45/month to run 24/7, so destroy when not in use. 
RDS is the most expensive piece at ~$15/month.

## Known issues / TODO

- SSH is open to 0.0.0.0/0 — fine for learning, would lock this down 
  in production
- No HTTPS yet — next step is adding ACM certificate
- DB password is in the config — should move to Secrets Manager
