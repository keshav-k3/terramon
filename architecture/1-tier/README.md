# 1-Tier Architecture

## Overview
A simple 1-tier architecture where all components (web server, application logic, and database) run on a single EC2 instance. This is suitable for development, testing, or very small applications.

## Architecture Diagram
```
Internet
    |
    v
Internet Gateway
    |
    v
Public Subnet
    |
    v
EC2 Instance (App + DB)
```

## Components
- **VPC**: Virtual Private Cloud with DNS support
- **Public Subnet**: Single subnet in one availability zone
- **Internet Gateway**: Provides internet access
- **EC2 Instance**: Single instance running the entire application stack
- **Security Group**: Controls inbound/outbound traffic

## Prerequisites
- AWS CLI configured
- Terraform installed (>= 1.0)
- SSH key pair created in AWS (optional)

## Usage

### Initialize Terraform
```bash
terraform init
```

### Plan Deployment
```bash
terraform plan
```

### Deploy
```bash
terraform apply
```

### Destroy
```bash
terraform destroy
```

## Customization
Edit `variables.tf` or create a `terraform.tfvars` file:

```hcl
aws_region         = "us-west-2"
project_name       = "myapp"
environment        = "production"
instance_type      = "t3.small"
key_name           = "my-key-pair"
ssh_cidr_blocks    = ["1.2.3.4/32"]
```

## Pros
- Simple to set up and manage
- Low cost
- Minimal infrastructure complexity

## Cons
- Single point of failure
- Not scalable
- Limited performance
- No high availability
- Security concerns (all components exposed)

## Best For
- Development environments
- POC/MVP applications
- Learning purposes
- Very low traffic applications
