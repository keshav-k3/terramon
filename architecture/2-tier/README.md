# 2-Tier Architecture

## Overview
A classic 2-tier architecture separating the application layer (web/app servers) from the database layer. The application tier runs in public subnets with an Application Load Balancer, while the database tier runs in private subnets with no direct internet access.

## Architecture Diagram
```
Internet
    |
    v
Internet Gateway
    |
    v
Application Load Balancer (Public Subnets)
    |
    v
Auto Scaling Group - EC2 Instances (Public Subnets)
    |
    v
NAT Gateway
    |
    v
RDS Database (Private Subnets)
```

## Components

### Network Layer
- **VPC**: Virtual Private Cloud with DNS support
- **Public Subnets**: 2 subnets across 2 availability zones for application tier
- **Private Subnets**: 2 subnets across 2 availability zones for database tier
- **Internet Gateway**: Provides internet access for public subnets
- **NAT Gateway**: Allows private subnets to access internet for updates

### Application Tier (Public)
- **Application Load Balancer**: Distributes traffic across app servers
- **Auto Scaling Group**: Automatically scales application servers (2-4 instances)
- **EC2 Instances**: Application servers running in multiple AZs
- **Security Group**: Controls inbound traffic from ALB and SSH access

### Database Tier (Private)
- **RDS MySQL Instance**: Managed database service
- **DB Subnet Group**: Spans multiple AZs for high availability
- **Security Group**: Only allows MySQL traffic from application tier

## Prerequisites
- AWS CLI configured
- Terraform installed (>= 1.0)
- SSH key pair created in AWS (optional, for EC2 access)

## Usage

### Initialize Terraform
```bash
terraform init
```

### Configure Database Password
Create a `terraform.tfvars` file:
```hcl
db_password = "YourSecurePassword123!"
db_username = "admin"
```

### Plan Deployment
```bash
terraform plan
```

### Deploy
```bash
terraform apply
```

### Access the Application
After deployment, get the ALB DNS name:
```bash
terraform output application_url
```

### Destroy
```bash
terraform destroy
```

## Customization
Edit `variables.tf` or create a `terraform.tfvars` file:

```hcl
aws_region             = "us-west-2"
project_name           = "myapp"
environment            = "production"
app_instance_type      = "t3.small"
asg_min_size           = 2
asg_max_size           = 6
asg_desired_capacity   = 3
db_instance_class      = "db.t3.small"
db_multi_az            = true
key_name               = "my-key-pair"
ssh_cidr_blocks        = ["1.2.3.4/32"]
```

## Security Features
- Database in private subnets (no internet access)
- Security groups with least privilege access
- Encrypted EBS volumes
- Encrypted RDS storage
- ALB for SSL termination (certificate required separately)
- SSH access restricted by IP

## High Availability
- Multi-AZ deployment for application tier
- Auto Scaling Group with min 2 instances
- Application Load Balancer health checks
- Optional multi-AZ RDS deployment
- Resources spread across 2 availability zones

## Pros
- Separation of concerns (app and database layers)
- Better security (database not publicly accessible)
- Scalable application tier with Auto Scaling
- High availability with multi-AZ deployment
- Load balancing for even traffic distribution
- Managed database service (automated backups, patching)

## Cons
- More complex than 1-tier
- Higher cost (ALB, NAT Gateway, RDS, multiple EC2s)
- Requires more configuration and management
- Database is still a potential bottleneck
- Single NAT Gateway can be a point of failure

## Best For
- Production web applications
- Small to medium-scale applications
- Applications requiring HA but not extreme scale
- Traditional LAMP/MEAN stack applications
- Applications with moderate traffic (< 10K requests/min)

## Cost Considerations
Main cost components:
- Application Load Balancer (~$16/month)
- NAT Gateway (~$32/month + data transfer)
- EC2 Instances (2+ instances)
- RDS Database instance
- EBS storage
- Data transfer costs

Estimated monthly cost: $100-300 depending on instance types and usage

## Monitoring and Maintenance
- Use CloudWatch for monitoring ALB, EC2, and RDS metrics
- Set up CloudWatch alarms for Auto Scaling
- Enable RDS automated backups (7-day retention included)
- Regular security group audits
- Monitor NAT Gateway data transfer costs
