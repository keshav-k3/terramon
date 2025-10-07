# Terramon - Terraform Infrastructure Guidelines

Enterprise-grade Terraform best practices for building secure, scalable, and maintainable infrastructure.

## Quick Start

### Prerequisites

- **Required MCP Server**: `hashicorp/terraform-mcp-server` for comprehensive Terraform provider access
- Terraform >= 1.5.0
- AWS Provider ~> 5.0

## Core Principles

### 1. Naming Conventions

Follow consistent naming standards:
- Use underscores (never dashes)
- Include environment prefixes: `prod_`, `dev_`, `staging_`
- Be descriptive about purpose
- Never include secrets in names

```hcl
# Example
resource "aws_instance" "prod_web_server" {
  # Configuration
}
```

### 2. Directory Structure

Standard project layout:

```
terraform-project/
├── main.tf              # Main resources
├── variables.tf         # Variable definitions
├── outputs.tf           # Output values
├── providers.tf         # Provider configuration
├── terraform.tfvars     # Values (gitignored)
├── versions.tf          # Version constraints
├── README.md            # Documentation
├── environments/        # Per-environment configs
└── modules/             # Reusable components
```

### 3. Modularization

Create modules when you have:
- Resources used across environments
- Complex configurations (3+ interconnected resources)
- Standardized security patterns

### 4. State Management

Never store state locally in production:
- Always use remote backend (S3 + DynamoDB)
- Always encrypt state
- Always enable state locking
- Separate state files per environment

```hcl
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

## Security First

### Security Rules

- **NEVER** hardcode credentials
- **ALWAYS** use IAM roles over access keys
- **ALWAYS** implement least privilege
- **ALWAYS** encrypt data at rest and in transit
- **ALWAYS** use current provider versions

### Tagging Strategy

Required tags for every resource:
- Environment
- Project
- ManagedBy (always "terraform")
- Owner
- CostCenter
- CreatedDate

## Validation & Quality

### Input Validation

Validate all inputs:

```hcl
variable "environment" {
  description = "Environment name"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}
```

### Security Groups

- Never use `0.0.0.0/0` for ingress unless absolutely necessary
- Always add descriptions
- Use security group references over CIDR blocks
- Implement least privilege access

## Quick Commands

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

# Cleanup
terraform destroy -var-file="environments/dev/terraform.tfvars"
```

## Pre-Deployment Checklist

- [ ] All resources follow naming conventions
- [ ] Directory structure is organized
- [ ] Remote state backend configured
- [ ] Sensitive data is secured
- [ ] Input validation implemented
- [ ] Output values defined
- [ ] Security groups follow least privilege
- [ ] All resources tagged properly
- [ ] Version constraints specified
- [ ] Code formatted (`terraform fmt`)
- [ ] Configuration validated (`terraform validate`)
- [ ] Plan reviewed (`terraform plan`)

## Git Workflow

- Always use feature branches
- Require pull request reviews
- Run `terraform plan` in CI
- Format and validate before commit
- Never commit `.tfvars` with secrets
- Use `.gitignore` for sensitive files

---

## Standards Compliance

These guidelines are compiled from official best practices established by industry leaders:

### HashiCorp Official Recommendations

- Collaborative Infrastructure as Code workflows using Terraform as core workflow
- Four stages of operational maturity for enterprise adoption
- Consistent code style with `terraform fmt` and `terraform validate`
- Workspace management with minimal blast radius
- Policy enforcement through HCP Terraform governance

### AWS Prescriptive Guidance

- Infrastructure code quality and consistency across Terraform projects
- Accelerated developer onboarding and contribution capabilities
- Increased business agility through faster infrastructure changes
- Reduced errors and downtime in infrastructure deployments
- Optimized infrastructure costs and strengthened security posture

### Firefly IaC Best Practices Guide

- Consistent, descriptive naming conventions for improved debugging and collaboration
- Standardized directory layouts for clarity, scalability, and efficiency
- Reusable modules that bundle common configurations for streamlined management
- Remote state storage, locking, backups, and access controls to prevent disasters
- Robust version control practices enabling rollbacks and audit trails
- CI/CD pipeline integration for automated validation, testing, and deployment
- Proactive security and governance measures with early vulnerability detection

### Enterprise Outcomes

Following these practices delivers:
- Secure infrastructure by default
- Scalable and maintainable deployments
- Consistent environments across dev/staging/prod
- Well-documented and team-accessible code
- Faster development cycles with reduced risk

---

*Compiled from HashiCorp Developer Documentation, AWS Prescriptive Guidance, Firefly IaC Best Practices Guide, and enterprise Infrastructure as Code standards*
