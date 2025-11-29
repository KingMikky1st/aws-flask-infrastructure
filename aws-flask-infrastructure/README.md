# Production-Ready Flask Application on AWS

**Built by:** Michael 
**AWS Certification:** Solutions Architect Associate  

## 🏗️ Architecture Overview

This project implements a highly available, scalable web application infrastructure on AWS with the following components:
- **VPC Architecture:** Multi-tier network with public/private subnets across 2 availability zones
- **Compute:** EC2 instance running Flask application with systemd service management
- **Database:** RDS PostgreSQL in private subnets for secure data persistence
- **Load Balancing:** Application Load Balancer with health checks for high availability
- **Storage:** S3 bucket with encryption and public access controls
- **Security:** Network segmentation via security groups following least privilege principle
```
                    Internet
                       │
                       ▼
              ┌──────────────────┐
              │  Load Balancer   │
              │   (Port 80)      │
              └────────┬─────────┘
                       │
           ┌───────────┴───────────┐
           ▼                       ▼
      ┌─────────┐             ┌─────────┐
      │   EC2   │             │   EC2   │
      │  Flask  │             │ (Future)│
      └────┬────┘             └─────────┘
           │
           ▼
    ┌──────────────┐
    │     RDS      │
    │  PostgreSQL  │
    └──────────────┘
```
---

## 🚀 Features

✅ **Infrastructure as Code:** 100% Terraform-managed, fully reproducible  
✅ **High Availability:** Multi-AZ deployment with load balancing  
✅ **Security First:** Private subnets, security groups, encrypted storage  
✅ **Production Ready:** Health checks, auto-restart services, monitoring hooks  
✅ **Automated Validation:** Python script to verify all components  
✅ **Cost Optimized:** Uses free-tier eligible resources where possible

---

## 📁 Project Structure
```
aws-flask-infrastructure/
├── terraform/
│   ├── main.tf              # Main infrastructure configuration
│   ├── modules/
│   │   └── vpc/
│   │       └── main.tf      # Reusable VPC module
├── scripts/
│   └── validate_infrastructure.py
├── docs/
│   └── ARCHITECTURE.md
└── README.md
```
---

## 🛠️ Technologies Used
- **Infrastructure as Code:** Terraform 1.0+
- **Cloud Provider:** AWS (EC2, RDS, VPC, ALB, S3, IAM)
- **Application:** Python 3.11, Flask
- **Web Server:** Nginx (reverse proxy)
- **Database:** PostgreSQL 15
- **Scripting:** Python (Boto3 SDK)
- **Version Control:** Git

---

## 📋 Prerequisites

- AWS Account with CLI configured
- Terraform >= 1.0
- Python 3.8+
- SSH key pair in AWS

---

## 🚀 Deployment Instructions

### 1. Clone Repository
```bash
git clone 
cd aws-flask-infrastructure/terraform
```

### 2. Configure Variables
Update `main.tf` with your settings:
- AWS region (default: us-east-1)
- Database password (change from default!)
- SSH key name

### 3. Deploy Infrastructure
```bash
terraform init
terraform plan
terraform apply
```
Type `yes` when prompted. Deployment takes ~10-15 minutes.

### 4. Get Application URL
```bash
terraform output load_balancer_url
```
Visit the URL in your browser after 2-3 minutes.

### 5. Validate Deployment
```bash
cd ../scripts
python validate_infrastructure.py
```

---
## 💰 Cost Estimate

**Monthly cost for 24/7 operation:**

| Service | Instance Type | Monthly Cost |
|---------|---------------|--------------|
| EC2 | t2.micro | ~$8.50 |
| RDS | db.t3.micro | ~$15 |
| ALB | Application LB | ~$16 |
| S3 | Standard storage | ~$1 |
| **Total** | | **~$40-45/month** |

**Cost Optimization Tips:**
- Destroy when not in use: `terraform destroy`
- Use t2.micro/t3.micro (free tier eligible)
- Stop RDS instance when not needed
- Enable S3 lifecycle policies

---

## 🧹 Cleanup

To avoid ongoing charges:
```bash
cd terraform
terraform destroy
```

Type `yes` to confirm. This removes ALL resources.

---

## 🔐 Security Considerations

- ✅ Database in private subnets (not internet-accessible)
- ✅ Security groups restrict traffic to necessary ports
- ✅ S3 bucket blocks public access
- ✅ IAM roles follow least privilege
- ⚠️ **Production recommendations:**
  - Use AWS Secrets Manager for database passwords
  - Enable CloudTrail for audit logging
  - Implement VPC Flow Logs
  - Add WAF for application protection
  - Use HTTPS with ACM certificates

---

## 📊 What I Learned

- **Multi-tier VPC architecture** with public/private subnet patterns
- **Infrastructure as Code best practices** using Terraform modules
- **AWS service integration** (EC2, RDS, ALB, S3, IAM)
- **Security group configuration** for network-level firewall rules
- **Load balancer health checks** and target group management
- **Python automation** with Boto3 for infrastructure validation
- **Production deployment patterns** (systemd services, reverse proxy)

---

## 🔮 Future Enhancements

- [ ] Add Auto Scaling Group for horizontal scaling
- [ ] Implement CloudWatch dashboards and alarms
- [ ] Add HTTPS with ACM certificate
- [ ] Implement CI/CD pipeline with GitHub Actions
- [ ] Add CloudFront CDN for static assets
- [ ] Implement backup automation for RDS
- [ ] Add container orchestration (ECS/EKS)

---

## 📝 License

This project is for educational and portfolio purposes.

---
## 🤝 Connect

**Michael**   
🎓 Computer Engineering @ University of Illinois Chicago  
🏆 AWS Certified Solutions Architect Associate

This project demonstrates enterprise cloud architecture patterns learned through:
- AWS Solutions Architect certification preparation
- Hands-on AWS experience
- Infrastructure as Code best practices
- Production deployment methodologies
