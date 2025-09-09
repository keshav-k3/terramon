# 🏗️ Terramon - Terraform Infrastructure Guidelines

Welcome to **Terramon**! 🎯 Your comprehensive guide to building secure, scalable, and maintainable infrastructure with Terraform.

## 🚀 Quick Start

This project follows enterprise-grade Terraform best practices to ensure your infrastructure is bulletproof and follows industry standards.

### 📋 Prerequisites

- 🔧 **Required MCP Server**: `hashicorp/terraform-mcp-server` for comprehensive Terraform provider access
- 🌱 Terraform >= 1.5.0
- ☁️ AWS Provider ~> 5.0

## 🎯 Core Principles

### 1. 📝 Naming That Makes Sense
We follow crystal-clear naming conventions:
- ✅ Use underscores (never dashes!)
- 🏷️ Include environment prefixes: `prod_`, `dev_`, `staging_`
- 📖 Be descriptive about purpose
- 🔒 Never include secrets in names

```hcl
# ✅ Perfect naming
resource "aws_instance" "prod_web_server" {
  # Your awesome config here
}
```

### 2. 📂 Directory Structure That Works
Keep everything organized with our battle-tested structure:

```
terraform-project/
├── 🏠 main.tf              # Your main resources
├── 🔧 variables.tf         # Variable definitions  
├── 📤 outputs.tf          # What you want to share
├── 🔌 providers.tf        # Provider magic
├── 📋 terraform.tfvars   # Values (gitignored!)
├── 📌 versions.tf         # Version constraints
├── 📖 README.md           # This beautiful file
├── 🌍 environments/       # Per-environment configs
└── 🧩 modules/            # Reusable components
```

### 3. 🧩 Smart Modularization
Create modules when you have:
- 🔄 Resources used across environments
- 🎯 Complex configurations (3+ interconnected resources)  
- 🔐 Standardized security patterns

### 4. 💾 State Management (Critical!)
Never store state locally in production:
- 🏠 Always use remote backend (S3 + DynamoDB)
- 🔒 Always encrypt state
- 🔐 Always enable state locking
- 📁 Separate state files per environment

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

## 🛡️ Security First

### 🔐 Golden Security Rules
- ❌ **NEVER** hardcode credentials
- ✅ **ALWAYS** use IAM roles over access keys
- 🎯 **ALWAYS** implement least privilege
- 🔒 **ALWAYS** encrypt data at rest and in transit
- 📦 **ALWAYS** use current provider versions

### 🏷️ Tagging Strategy
Every resource gets these mandatory tags:
- 🌍 Environment
- 📋 Project  
- 🤖 ManagedBy (always "terraform")
- 👤 Owner
- 💰 CostCenter
- 📅 CreatedDate

## 🔍 Validation & Quality

### ✅ Input Validation
We validate everything:

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

### 🚦 Security Groups Done Right
- 🚫 Never use `0.0.0.0/0` for ingress unless absolutely necessary
- 📝 Always add descriptions
- 🔗 Use security group references over CIDR blocks
- 🎯 Implement least privilege access

## 🚀 Quick Commands

```bash
# 🏁 Initialize and validate
terraform init
terraform validate
terraform fmt -recursive

# 📋 Plan and apply
terraform plan -var-file="environments/dev/terraform.tfvars"
terraform apply -var-file="environments/dev/terraform.tfvars"

# 🔍 State operations
terraform state list
terraform state show <resource>

# 🧹 Cleanup
terraform destroy -var-file="environments/dev/terraform.tfvars"
```

## ✅ Pre-Deployment Checklist

Before hitting that apply button, make sure:

- [ ] 📝 All resources follow naming conventions
- [ ] 📂 Directory structure is organized
- [ ] 💾 Remote state backend configured
- [ ] 🔒 Sensitive data is secured
- [ ] ✅ Input validation implemented
- [ ] 📤 Output values defined
- [ ] 🛡️ Security groups follow least privilege
- [ ] 🏷️ All resources tagged properly
- [ ] 📌 Version constraints specified
- [ ] 🎨 Code formatted (`terraform fmt`)
- [ ] ✅ Configuration validated (`terraform validate`)
- [ ] 📋 Plan reviewed (`terraform plan`)

## 🎯 Git Workflow

- 🌟 Always use feature branches
- 👥 Require pull request reviews
- 🤖 Run `terraform plan` in CI
- ✨ Format and validate before commit
- 🚫 Never commit `.tfvars` with secrets
- 📋 Use `.gitignore` for sensitive files

---

## 🤝 Contributing

Follow these guidelines and your infrastructure will be:
- 🔒 **Secure** by default
- 📈 **Scalable** and maintainable  
- 🎯 **Consistent** across environments
- 📖 **Well-documented** and clear

Remember: These rules aren't just suggestions—they're your infrastructure's best friends! 🚀

---

*Built with ❤️ using Terraform best practices*