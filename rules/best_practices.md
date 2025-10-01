# AWS Terraform Best Practices Guide

You are an expert in Terraform and Infrastructure as Code (IaC) specifically for AWS cloud infrastructure. This guide focuses on AWS-specific best practices for building, maintaining, and scaling cloud infrastructure.

## 🎯 Core Principles

- **Infrastructure as Code**: All AWS infrastructure must be defined in Terraform code
- **Immutable Infrastructure**: Prefer replacing resources over modifying them in place
- **Modular Design**: Create reusable, composable modules for common AWS patterns
- **Version Everything**: Lock provider versions, module versions, and use semantic versioning
- **Security by Default**: Apply least privilege access and encryption by default
- **Cost Optimization**: Implement tagging strategies and resource right-sizing

## 🔧 AWS Provider and Backend Configuration

### Provider Version Locking
```hcl
terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment   = var.environment
      Project       = var.project_name
      ManagedBy     = "terraform"
      CostCenter    = var.cost_center
    }
  }
}
```

### S3 Backend with DynamoDB State Locking
```hcl
terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket"
    key            = "infrastructure/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"

    # Optional: Use KMS for additional encryption
    kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
  }
}
```

## 🔐 Security Best Practices

### IAM Policies and Roles
- **Principle of Least Privilege**: Grant minimum necessary permissions
- **Use IAM Roles**: Prefer roles over users for service access
- **Policy Attachments**: Use `aws_iam_role_policy_attachment` for managed policies
- **Resource-Based Policies**: Implement for cross-account access

```hcl
# Example: IAM role for EC2 with specific permissions
resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}
```

### Secrets Management
- **AWS Secrets Manager**: Store sensitive data like database passwords
- **Parameter Store**: Use for configuration values and non-secret parameters
- **Never Hardcode**: No sensitive values in Terraform code or state

```hcl
resource "aws_secretsmanager_secret" "db_password" {
  name                    = "${var.project_name}-db-password"
  description             = "Database password"
  recovery_window_in_days = 7

  kms_key_id = aws_kms_key.secrets.arn
}
```

### Encryption Standards
- **Encryption at Rest**: Enable for all storage services (S3, EBS, RDS)
- **Encryption in Transit**: Use TLS for all communications
- **KMS Key Management**: Use customer-managed keys for sensitive workloads

## 🏗️ AWS Resource Organization

### File Structure
```
terraform/
├── environments/
│   ├── dev/
│   ├── staging/
│   └── prod/
├── modules/
│   ├── vpc/
│   ├── ec2/
│   ├── rds/
│   └── s3/
├── shared/
│   ├── backend.tf
│   └── provider.tf
└── global/
    ├── iam/
    └── route53/
```

### Workspace Strategy
```bash
# Environment separation using workspaces
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod
```

### Resource Naming Convention
```hcl
locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    Team        = var.team
    ManagedBy   = "terraform"
  }
}

resource "aws_s3_bucket" "example" {
  bucket = "${local.name_prefix}-data-bucket"
  tags   = local.common_tags
}
```

## 📦 Module Guidelines

### Module Structure
```
modules/vpc/
├── main.tf
├── variables.tf
├── outputs.tf
├── versions.tf
└── README.md
```

### Module Versioning
```hcl
module "vpc" {
  source  = "git::https://github.com/your-org/terraform-aws-vpc.git?ref=v1.2.0"

  cidr_block           = var.vpc_cidr
  availability_zones   = data.aws_availability_zones.available.names
  environment         = var.environment
}
```

### Data Sources vs Resources
- Use data sources for existing AWS resources
- Prefer data sources over hardcoded ARNs or IDs

```hcl
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}
```

## 💰 Cost Optimization

### Tagging Strategy for Cost Management
```hcl
locals {
  cost_tags = {
    CostCenter    = var.cost_center
    Environment   = var.environment
    Project       = var.project_name
    Owner         = var.owner
    CreatedBy     = "terraform"
    CreatedDate   = formatdate("YYYY-MM-DD", timestamp())
  }
}
```

### Resource Right-Sizing
```hcl
variable "instance_types" {
  description = "Instance types by environment"
  type        = map(string)
  default = {
    dev     = "t3.micro"
    staging = "t3.small"
    prod    = "t3.medium"
  }
}

resource "aws_instance" "web" {
  instance_type = var.instance_types[var.environment]
  # ... other configuration
}
```

### Spot Instances and Savings Plans
```hcl
resource "aws_spot_instance_request" "worker" {
  count = var.environment == "prod" ? 0 : var.worker_count

  ami                  = data.aws_ami.amazon_linux.id
  instance_type        = "t3.medium"
  spot_price          = "0.05"
  wait_for_fulfillment = true
}
```

## 📊 Monitoring and Compliance

### CloudTrail Integration
```hcl
resource "aws_cloudtrail" "audit" {
  name           = "${var.project_name}-audit-trail"
  s3_bucket_name = aws_s3_bucket.audit_logs.bucket

  enable_logging                = true
  include_global_service_events = true
  is_multi_region_trail        = true

  event_selector {
    read_write_type                 = "All"
    include_management_events       = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["${aws_s3_bucket.sensitive.arn}/*"]
    }
  }
}
```

### AWS Config Rules
```hcl
resource "aws_config_configuration_recorder" "recorder" {
  name     = "${var.project_name}-config-recorder"
  role_arn = aws_iam_role.config.arn

  recording_group {
    all_supported = true
  }
}
```

## 🧪 Testing and Validation

### Validation Rules
```hcl
variable "environment" {
  description = "Environment name"
  type        = string

  validation {
    condition = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}
```

### Pre-commit Hooks
```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.83.5
    hooks:
      - id: terraform_fmt
      - id: terraform_validate
      - id: terraform_tflint
      - id: terraform_checkov
```

### Terratest Integration
```go
func TestVPCModule(t *testing.T) {
    terraformOptions := &terraform.Options{
        TerraformDir: "../modules/vpc",
        Vars: map[string]interface{}{
            "cidr_block": "10.0.0.0/16",
            "environment": "test",
        },
    }

    defer terraform.Destroy(t, terraformOptions)
    terraform.InitAndApply(t, terraformOptions)

    vpcId := terraform.Output(t, terraformOptions, "vpc_id")
    assert.NotEmpty(t, vpcId)
}
```

## ⚡ Performance Optimization

### Parallel Resource Creation
```hcl
# Use for_each for parallel resource creation
resource "aws_subnet" "private" {
  for_each = toset(var.availability_zones)

  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, index(var.availability_zones, each.value) + 100)
  availability_zone = each.value

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-private-${each.value}"
    Type = "private"
  })
}
```

### Resource Targeting
```bash
# Target specific resources for faster deployments
terraform apply -target=module.vpc
terraform apply -target=aws_security_group.web
```

### State Management
```bash
# Import existing resources
terraform import aws_instance.web i-1234567890abcdef0

# Remove resources from state without destroying
terraform state rm aws_instance.redundant
```

## 🚀 CI/CD Integration

### GitHub Actions Example
```yaml
name: Terraform AWS
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  terraform:
    runs-on: ubuntu-latest
    env:
      AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
      AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}

    steps:
      - uses: actions/checkout@v3

      - uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.5.0

      - name: Terraform Init
        run: terraform init

      - name: Terraform Plan
        run: terraform plan -out=tfplan

      - name: Terraform Apply
        if: github.ref == 'refs/heads/main'
        run: terraform apply tfplan
```

## 📚 Documentation Standards

### Module Documentation
```hcl
# README.md template for modules
## Usage
```hcl
module "vpc" {
  source = "./modules/vpc"

  cidr_block         = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b"]
  environment       = "prod"
}
```

## Requirements
| Name | Version |
|------|---------|
| terraform | >= 1.5 |
| aws | ~> 5.0 |

## Providers
| Name | Version |
|------|---------|
| aws | ~> 5.0 |

## Inputs
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cidr_block | VPC CIDR block | `string` | n/a | yes |
```

### Code Comments
```hcl
# Create VPC with DNS support enabled
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-vpc"
  })
}
```

## 🎯 Key Conventions

1. **Always pin provider versions** to avoid breaking changes
2. **Use consistent tagging** across all AWS resources for cost tracking
3. **Implement least privilege IAM** policies for all resources
4. **Enable encryption** by default for all storage and database services
5. **Use data sources** instead of hardcoded resource IDs
6. **Validate inputs** with appropriate validation rules
7. **Document modules** with clear examples and requirements
8. **Test infrastructure** with automated testing tools
9. **Monitor costs** with proper tagging and cost allocation
10. **Follow naming conventions** for consistency across environments

## 📖 AWS-Specific Resources

- [AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Architecture Center](https://aws.amazon.com/architecture/)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [AWS Security Best Practices](https://aws.amazon.com/security/security-resources/)
- [AWS Cost Optimization](https://aws.amazon.com/aws-cost-management/)