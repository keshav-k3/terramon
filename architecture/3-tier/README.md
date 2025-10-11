# 3-Tier Architecture

## Overview
A classic 3-tier architecture that separates the presentation layer (web servers), business logic layer (application servers), and data layer (database). Each tier runs in its own subnet with appropriate security controls, providing maximum separation of concerns and security.

## Architecture Diagram
```
Internet
    |
    v
Internet Gateway
    |
    v
Public ALB (Web Tier - Public Subnets)
    |
    v
Web Servers - Auto Scaling Group (Public Subnets)
    |
    v
Internal ALB (Application Tier - Private Subnets)
    |
    v
Application Servers - Auto Scaling Group (Private Subnets)
    |
    v
RDS Database (Database Tier - Private Subnets)
```

## Components

### Network Layer
- **VPC**: Virtual Private Cloud with DNS support
- **Public Subnets**: 2 subnets across 2 AZs for web tier (with internet access)
- **Private App Subnets**: 2 subnets across 2 AZs for application tier
- **Private DB Subnets**: 2 subnets across 2 AZs for database tier
- **Internet Gateway**: Provides internet access for public subnets
- **NAT Gateway**: Allows private subnets to access internet for updates

### Web Tier (Public)
- **External Application Load Balancer**: Internet-facing load balancer
- **Auto Scaling Group**: Web servers (2-4 instances)
- **EC2 Instances**: Nginx/Apache web servers serving static content
- **Security Group**: Allows HTTP/HTTPS from internet, forwards to app tier

### Application Tier (Private)
- **Internal Application Load Balancer**: Private load balancer for app servers
- **Auto Scaling Group**: Application servers (2-4 instances)
- **EC2 Instances**: Application logic (Java, Node.js, Python, etc.)
- **Security Group**: Only accepts traffic from web tier

### Database Tier (Private)
- **RDS MySQL Instance**: Managed database service
- **DB Subnet Group**: Spans multiple AZs for high availability
- **Security Group**: Only allows MySQL traffic from application tier
- **Multi-AZ**: Optional high availability configuration

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
After deployment, get the web ALB DNS name:
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
aws_region               = "us-west-2"
project_name             = "myapp"
environment              = "production"
web_instance_type        = "t3.small"
app_instance_type        = "t3.medium"
web_asg_min_size         = 2
web_asg_max_size         = 6
app_asg_min_size         = 2
app_asg_max_size         = 8
db_instance_class        = "db.t3.small"
db_multi_az              = true
key_name                 = "my-key-pair"
ssh_cidr_blocks          = ["1.2.3.4/32"]
```

## Security Features
- **Three-layer isolation**: Web, application, and database in separate subnets
- **Defense in depth**: Multiple security groups for each tier
- **Private application tier**: No direct internet access
- **Private database tier**: Completely isolated, no internet route
- **Encrypted storage**: EBS and RDS encryption enabled
- **Security groups**: Least privilege access between tiers
- **NAT Gateway**: Secure outbound internet for private subnets

## Traffic Flow
1. User → Internet → Internet Gateway
2. Internet Gateway → External ALB (Public Subnet)
3. External ALB → Web Servers (Public Subnet)
4. Web Servers → Internal ALB (Private App Subnet)
5. Internal ALB → Application Servers (Private App Subnet)
6. Application Servers → RDS Database (Private DB Subnet)

## High Availability
- Multi-AZ deployment for all tiers
- Auto Scaling Groups for web and application tiers
- Two load balancers with health checks
- Optional multi-AZ RDS for database failover
- Resources spread across 2 availability zones
- Automatic replacement of unhealthy instances

## Pros
- **Maximum security**: Complete tier isolation
- **Scalability**: Each tier scales independently
- **High availability**: Multi-AZ and auto scaling
- **Flexibility**: Can use different technologies per tier
- **Maintainability**: Clear separation of concerns
- **Performance**: Can optimize each tier independently
- **Best practices**: Industry-standard architecture

## Cons
- **Complexity**: Most complex to set up and manage
- **Cost**: Highest cost (2 ALBs, NAT Gateway, multiple EC2s, RDS)
- **Management overhead**: More components to monitor and maintain
- **Learning curve**: Requires understanding of all components

## Best For
- Production enterprise applications
- Applications requiring high security
- Applications with complex business logic
- High-traffic applications (10K+ requests/min)
- Applications requiring PCI/HIPAA compliance
- Microservices architectures
- Applications requiring independent scaling of tiers

## Cost Considerations
Main cost components:
- External Application Load Balancer (~$16/month)
- Internal Application Load Balancer (~$16/month)
- NAT Gateway (~$32/month + data transfer)
- Web Tier EC2 Instances (2+ instances)
- Application Tier EC2 Instances (2+ instances)
- RDS Database instance
- EBS storage (multiple instances)
- Data transfer costs

Estimated monthly cost: $200-500+ depending on instance types and usage

## Monitoring and Maintenance
- Use CloudWatch for monitoring all components
- Set up CloudWatch alarms for Auto Scaling
- Monitor ALB metrics (request count, latency, errors)
- Enable RDS automated backups (7-day retention)
- Regular security group audits
- Monitor NAT Gateway data transfer costs
- Set up CloudWatch Logs for application logs
- Use CloudWatch Container Insights if using containers

## Scaling Strategy
- **Web Tier**: Scale based on HTTP request count
- **Application Tier**: Scale based on CPU/Memory utilization
- **Database Tier**: Use read replicas for read-heavy workloads
- Consider using ElastiCache for caching layer

## Migration Path
1. Start with 1-tier for development
2. Move to 2-tier for small production
3. Upgrade to 3-tier as traffic/security needs grow
4. Consider serverless or containers for further optimization
