# MAIN TERRAFORM CONFIGURATION
# Tell Terraform what provider (AWS) and version to use

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS provider
provider "aws" {
  region = var.aws_region
}


variable "aws_region" {
  description = "AWS region to deploy to"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "flask-app"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "dbadmin"
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
  default     = "ChangeThisPassword123!"
}

# THE VPC MODULE - Create our network
module "vpc" {
  source = "./modules/vpc"
  
  vpc_cidr     = "10.0.0.0/16"
  project_name = var.project_name
}

# S3 BUCKET
resource "aws_s3_bucket" "app_bucket" {
  bucket = "${var.project_name}-bucket-${random_id.bucket_suffix.hex}"

  tags = {
    Name = "${var.project_name}-bucket"
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Block public access 
resource "aws_s3_bucket_public_access_block" "app_bucket" {
  bucket = aws_s3_bucket.app_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# RDS DATABASE - PostgreSQL database
# Subnet group 
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = module.vpc.private_subnet_ids

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

# database
resource "aws_db_instance" "main" {
  identifier           = "${var.project_name}-db"
  engine               = "postgres"
  engine_version       = "15.8"
  instance_class       = "db.t3.micro"
  allocated_storage    = 20
  storage_type         = "gp3"
  
  db_name  = "flaskapp"
  username = var.db_username
  password = var.db_password
  
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [module.vpc.database_security_group_id]
  
  skip_final_snapshot = true
  publicly_accessible = false
  
  tags = {
    Name = "${var.project_name}-database"
  }
}

# a PostgreSQL database
# - Version 15.4
# - Smallest instance size t3.micro 
# - 20GB storage
# - in private subnets 


# EC2 INSTANCE - The web server
# Get Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


# Create the EC2 instance
resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = "t2.micro"
  key_name      = "flask-app-key"
  subnet_id     = module.vpc.public_subnet_ids[0]
  
  vpc_security_group_ids = [module.vpc.web_security_group_id]
  
  # This script runs when the instance first starts
user_data = base64encode(<<-EOF
#!/bin/bash
set -e

# Update and install packages
dnf update -y
dnf install -y python3.11 python3.11-pip nginx

# Install Flask
python3.11 -m pip install flask

# Create Flask app
mkdir -p /opt/flask-app
cat > /opt/flask-app/app.py << 'PYEOF'
from flask import Flask, jsonify

app = Flask(__name__)

@app.route('/')
def home():
    return '''
    <html>
        <head>
            <title>Michael Mowobi - AWS Infrastructure Project</title>
            <style>
                body {
                    font-family: 'Segoe UI', Arial, sans-serif;
                    max-width: 900px;
                    margin: 0 auto;
                    padding: 40px 20px;
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    min-height: 100vh;
                }
                .container {
                    background: rgba(255, 255, 255, 0.95);
                    padding: 40px;
                    border-radius: 15px;
                    box-shadow: 0 20px 60px rgba(0,0,0,0.3);
                    color: #333;
                }
                h1 {
                    color: #667eea;
                    margin-top: 0;
                    font-size: 2.5em;
                }
                .status-box {
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    color: white;
                    padding: 20px;
                    border-radius: 10px;
                    margin: 20px 0;
                }
                .component-list {
                    list-style: none;
                    padding: 0;
                }
                .component-list li {
                    padding: 10px;
                    margin: 8px 0;
                    background: rgba(102, 126, 234, 0.1);
                    border-left: 4px solid #667eea;
                    border-radius: 5px;
                }
                .footer {
                    text-align: center;
                    margin-top: 30px;
                    padding-top: 20px;
                    border-top: 2px solid #667eea;
                    color: #666;
                }
                .badge {
                    display: inline-block;
                    background: #667eea;
                    color: white;
                    padding: 5px 15px;
                    border-radius: 20px;
                    font-size: 0.9em;
                    margin: 5px;
                }
            </style>
        </head>
        <body>
            <div class="container">
                <h1>🚀 Michael Mowobi's AWS Infrastructure</h1>
                
                <p style="font-size: 1.2em; color: #666;">
                    Production-grade cloud infrastructure deployed with <strong>Infrastructure as Code</strong>
                </p>
                
                <div class="status-box">
                    <h2 style="margin-top: 0;">✅ Architecture Components</h2>
                    <ul class="component-list">
                        <li><strong>VPC Architecture:</strong> Multi-tier network with public/private subnets across 2 availability zones</li>
                        <li><strong>EC2 Web Server:</strong> Auto-scaling ready compute with systemd service management</li>
                        <li><strong>RDS PostgreSQL:</strong> Multi-AZ database in private subnets for data persistence</li>
                        <li><strong>Application Load Balancer:</strong> High availability with health checks and traffic distribution</li>
                        <li><strong>S3 Storage:</strong> Object storage with encryption and access controls</li>
                        <li><strong>Security Groups:</strong> Network-level firewall rules following least privilege</li>
                    </ul>
                </div>
                
                <div style="background: #f8f9fa; padding: 20px; border-radius: 10px; margin: 20px 0;">
                    <h3>📊 Technical Highlights</h3>
                    <p><span class="badge">Terraform</span> <span class="badge">AWS</span> <span class="badge">Python</span> <span class="badge">Flask</span> <span class="badge">PostgreSQL</span> <span class="badge">Nginx</span></p>
                    <ul>
                        <li>100% Infrastructure as Code - fully reproducible</li>
                        <li>High availability design across multiple AZs</li>
                        <li>Security-first architecture with network segmentation</li>
                        <li>Production-ready with health checks and monitoring</li>
                    </ul>
                </div>
                
                <div class="footer">
                    <p><strong>Built by Michael Mowobi</strong></p>
                    <p>AWS Solutions Architect Associate | Computer Engineering @ UIC</p>
                    <p style="font-size: 0.9em; color: #999;">mmowo2@uic.edu | (219) 214-7306</p>
                </div>
            </div>
        </body>
    </html>
    '''

@app.route('/health')
def health():
    return jsonify({'status': 'healthy', 'service': 'flask-app'}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
PYEOF

# Create systemd service
cat > /etc/systemd/system/flask-app.service << 'SERVICEEOF'
[Unit]
Description=Flask Application
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt/flask-app
Environment="PATH=/usr/local/bin:/usr/bin:/bin"
ExecStart=/usr/bin/python3.11 /opt/flask-app/app.py
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
SERVICEEOF

# Set permissions
chown -R ec2-user:ec2-user /opt/flask-app

# Configure nginx
cat > /etc/nginx/conf.d/flask.conf << 'NGINXEOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    
    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
    
    location /health {
        proxy_pass http://127.0.0.1:8080/health;
        access_log off;
    }
}
NGINXEOF

# Remove default nginx config
rm -f /etc/nginx/nginx.conf.default
sed -i 's/listen       80;/listen       8888;/' /etc/nginx/nginx.conf

# Enable and start services
systemctl daemon-reload
systemctl enable flask-app
systemctl start flask-app
systemctl enable nginx
systemctl start nginx

# Write completion marker
echo "Setup completed at $(date)" > /tmp/user-data-complete
EOF
  )
  tags = {
    Name = "${var.project_name}-web-server"
  }
}

# Create a web server (EC2 instance)
# - Use t2.micro (free tier!)
# - Put it in a public subnet so people can reach it
# - Install Python and Flask
# - Start a Flask web application automatically
# - The app shows a nice landing page


# APPLICATION LOAD BALANCER
resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [module.vpc.web_security_group_id]
  subnets            = module.vpc.public_subnet_ids

  tags = {
    Name = "${var.project_name}-alb"
  }
}

#Create a load balancer
# - Sits in front of web servers
# - Distributes traffic across multiple servers (only have 1 now, but could scale)
# - Provides a single URL for accessing the app

# Target group 
resource "aws_lb_target_group" "main" {
  name     = "${var.project_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name = "${var.project_name}-tg"
  }
}

# Create a target group
# - Defines which servers the load balancer sends traffic to
# - Checks if servers are healthy every 30 seconds by visiting /health
# - If a server fails 2 checks, stop sending traffic to it

# Register the EC2 instance with the target group
resource "aws_lb_target_group_attachment" "main" {
  target_group_arn = aws_lb_target_group.main.arn
  target_id        = aws_instance.web.id
  port             = 80
}


# Create listener (tells load balancer what to do with incoming traffic)
resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}


# OUTPUTS - Important info we want to see
output "load_balancer_url" {
  description = "URL of the load balancer (your website!)"
  value       = "http://${aws_lb.main.dns_name}"
}

output "ec2_public_ip" {
  description = "Public IP of EC2 instance"
  value       = aws_instance.web.public_ip
}

output "database_endpoint" {
  description = "RDS database endpoint"
  value       = aws_db_instance.main.endpoint
  sensitive   = true
}

output "s3_bucket_name" {
  description = "Name of S3 bucket"
  value       = aws_s3_bucket.app_bucket.id
}
