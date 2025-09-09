# Infrastructure.md - Terraform Best Practices for Agents

## Dev Notes - Required MCP Integration

**Required MCP Server:**
- `hashicorp/terraform-mcp-server` - Official Terraform MCP providing comprehensive provider access, module management, and Terraform ecosystem integration. Use this MCP whenever you need to access Terraform providers, resources, data sources, or any Terraform Registry functionality.

---

## Core Infrastructure-as-Code Principles

### 1. Resource Naming Standards

**ALWAYS follow these naming conventions:**

```hcl
# ✅ CORRECT - Clear, descriptive, environment-aware
resource "aws_instance" "prod_web_server" {
  # configuration
}

resource "aws_s3_bucket" "dev_application_logs" {
  # configuration
}

resource "aws_rds_instance" "staging_database_main" {
  # configuration
}
```

**Naming Rules:**
- Use underscores, never dashes or spaces
- Include environment prefix: `prod_`, `dev_`, `staging_`
- Be descriptive about the resource's purpose
- Keep names concise but clear
- Never include sensitive data, secrets, or internal codes in names

### 2. Directory Structure Organization

**MANDATORY directory structure:**

```
terraform-project/
├── main.tf              # Primary resources
├── variables.tf         # Variable definitions
├── outputs.tf          # Output values
├── providers.tf        # Provider configurations
├── terraform.tfvars   # Variable values (gitignored)
├── versions.tf         # Provider version constraints
├── README.md           # Project documentation
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── terraform.tfvars
│   ├── staging/
│   └── prod/
└── modules/
    ├── vpc/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── security-group/
    └── database/
```

**Key Rules:**
- Core `.tf` files MUST be in project root
- Environment-specific configurations MUST be in separate directories
- Reusable components MUST be organized under `modules/`
- Each module MUST have its own `variables.tf` and `outputs.tf`

### 3. Modularization Strategy

**When to create modules:**
- Any resource group used in multiple environments
- Complex configurations with 3+ interconnected resources
- Resources that need standardized security configurations

**Module structure example:**

```hcl
# modules/vpc/main.tf
resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.common_tags, {
    Name = "${var.environment}_vpc_main"
  })
}

# modules/vpc/variables.tf
variable "cidr_block" {
  description = "CIDR block for VPC"
  type        = string
  validation {
    condition     = can(cidrhost(var.cidr_block, 0))
    error_message = "Must be a valid CIDR block."
  }
}

variable "environment" {
  description = "Environment name"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
```

### 4. State Management Requirements

**MANDATORY state configuration:**

```hcl
# backend.tf
terraform {
  backend "s3" {
    bucket         = "company-terraform-state"
    key            = "environments/prod/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

**State Management Rules:**
- NEVER store state files locally in production
- ALWAYS use remote backend (S3 + DynamoDB for AWS)
- ALWAYS enable state encryption
- ALWAYS enable state locking
- Use separate state files for each environment
- Implement state backup strategy with versioning

### 5. Security Configuration Standards

**Provider security configuration:**

```hcl
# providers.tf
terraform {
  required_version = ">= 1.0"
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
      Owner         = var.owner
      CostCenter    = var.cost_center
    }
  }
}
```

**Security Rules:**
- NEVER hardcode credentials in `.tf` files
- ALWAYS use IAM roles, never access keys when possible
- ALWAYS implement least privilege access
- ALWAYS encrypt sensitive data at rest and in transit
- ALWAYS use current provider versions with security patches

### 6. Variable and Output Standards

**Variable definitions with validation:**

```hcl
# variables.tf
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
  
  validation {
    condition = contains([
      "t3.micro", "t3.small", "t3.medium",
      "t3.large", "m5.large", "m5.xlarge"
    ], var.instance_type)
    error_message = "Instance type must be approved size."
  }
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed for access"
  type        = list(string)
  
  validation {
    condition = alltrue([
      for cidr in var.allowed_cidr_blocks : can(cidrhost(cidr, 0))
    ])
    error_message = "All values must be valid CIDR blocks."
  }
}
```

**Output definitions:**

```hcl
# outputs.tf
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = aws_subnet.private[*].id
  sensitive   = false
}

output "database_endpoint" {
  description = "Database endpoint"
  value       = aws_rds_instance.main.endpoint
  sensitive   = true
}
```

### 7. Resource Tagging Strategy

**MANDATORY tags for all resources:**

```hcl
locals {
  common_tags = {
    Environment   = var.environment
    Project       = var.project_name
    ManagedBy     = "terraform"
    Owner         = var.owner
    CostCenter    = var.cost_center
    CreatedDate   = formatdate("YYYY-MM-DD", timestamp())
  }
}

resource "aws_instance" "web_server" {
  # ... other configuration
  
  tags = merge(local.common_tags, {
    Name = "${var.environment}_web_server"
    Role = "web-server"
    Backup = "daily"
  })
}
```

### 8. Security Group Best Practices

**Secure security group configuration:**

```hcl
resource "aws_security_group" "web_server" {
  name_prefix = "${var.environment}_web_server_"
  vpc_id      = var.vpc_id
  description = "Security group for web servers"

  # Ingress rules - be specific
  ingress {
    description = "HTTPS from ALB"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description = "HTTP from ALB"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # Egress rules - restrictive
  egress {
    description = "HTTPS outbound"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.environment}_web_server_sg"
  })
}
```

**Security Group Rules:**
- NEVER use `0.0.0.0/0` for ingress unless absolutely necessary
- ALWAYS specify descriptions for all rules
- ALWAYS use security group references instead of CIDR blocks when possible
- ALWAYS implement least privilege access
- ALWAYS use `name_prefix` instead of `name` for dynamic naming

### 9. Data Sources and Remote State

**Using data sources for existing resources:**

```hcl
# Get existing VPC
data "aws_vpc" "existing" {
  filter {
    name   = "tag:Name"
    values = ["${var.environment}_vpc_main"]
  }
}

# Get AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Remote state reference
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "company-terraform-state"
    key    = "environments/${var.environment}/vpc/terraform.tfstate"
    region = "us-west-2"
  }
}
```

### 10. Version Control and CI/CD Integration

**Version constraints:**

```hcl
# versions.tf
terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.4"
    }
  }
}
```

**Git workflow requirements:**
- ALWAYS use feature branches for changes
- ALWAYS require pull request reviews
- ALWAYS run `terraform plan` in CI before merge
- ALWAYS validate and format code before commit
- NEVER commit `.tfvars` files with sensitive data
- ALWAYS use `.gitignore` for state files and sensitive data

### 11. Common Resource Patterns

**EC2 Instance with security:**

```hcl
resource "aws_instance" "web_server" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = var.private_subnet_id
  vpc_security_group_ids = [aws_security_group.web_server.id]
  
  # Security hardening
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
    http_put_response_hop_limit = 1
  }
  
  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
    
    tags = merge(local.common_tags, {
      Name = "${var.environment}_web_server_root"
    })
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    environment = var.environment
  }))

  tags = merge(local.common_tags, {
    Name = "${var.environment}_web_server"
    Role = "web-server"
  })
}
```

**S3 Bucket with security:**

```hcl
resource "aws_s3_bucket" "app_data" {
  bucket = "${var.environment}-${var.project_name}-app-data-${random_id.bucket_suffix.hex}"
  
  tags = merge(local.common_tags, {
    Name = "${var.environment}_app_data_bucket"
  })
}

resource "aws_s3_bucket_encryption_configuration" "app_data" {
  bucket = aws_s3_bucket.app_data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "app_data" {
  bucket = aws_s3_bucket.app_data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "app_data" {
  bucket = aws_s3_bucket.app_data.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}
```

### 12. Error Handling and Validation

**Input validation patterns:**

```hcl
variable "environment" {
  description = "Environment name"
  type        = string
  
  validation {
    condition = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  
  validation {
    condition = can(cidrhost(var.vpc_cidr, 0)) && can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/[0-9]{1,2}$", var.vpc_cidr))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}
```

**Lifecycle management:**

```hcl
resource "aws_instance" "web_server" {
  # ... configuration

  lifecycle {
    create_before_destroy = true
    prevent_destroy       = true
    
    ignore_changes = [
      ami,  # Prevent recreation on AMI updates
      user_data,  # Ignore user_data changes after creation
    ]
  }
}
```

---

## Implementation Checklist

Before applying any Terraform configuration, verify:

- [ ] All resources follow naming conventions
- [ ] Directory structure is properly organized
- [ ] Remote state backend is configured
- [ ] All sensitive data is properly secured
- [ ] Input validation is implemented
- [ ] Output values are properly defined
- [ ] Security groups follow least privilege
- [ ] All resources are properly tagged
- [ ] Version constraints are specified
- [ ] Code is formatted (`terraform fmt`)
- [ ] Configuration is validated (`terraform validate`)
- [ ] Plan is reviewed (`terraform plan`)

## Quick Reference Commands

```bash
# Initialize and validate
terraform init
terraform validate
terraform fmt -recursive

# Plan and apply
terraform plan -var-file="environments/dev/terraform.tfvars"
terraform apply -var-file="environments/dev/terraform.tfvars"

# State operations
terraform state list
terraform state show <resource>
terraform import <resource> <id>

# Cleanup
terraform destroy -var-file="environments/dev/terraform.tfvars"
```

---

**Remember:** These rules ensure secure, maintainable, and scalable infrastructure deployments. Always use the `hashicorp/terraform-mcp-server` for provider information, resource documentation, and module discovery.