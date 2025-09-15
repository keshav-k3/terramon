# AWS Billing Alerts with Terraform

This Terraform configuration sets up an automated AWS billing alert system that sends daily cost reports via webhook to Slack, Teams, Discord, or other platforms.

## Architecture

- **Lambda Function**: Retrieves billing data using AWS Cost Explorer API
- **EventBridge Rule**: Triggers the function daily at 9 AM JST
- **IAM Role & Policy**: Provides necessary permissions for Cost Explorer access
- **Webhook Integration**: Sends formatted billing reports via webhook (Slack, Teams, Discord, etc.)

## Prerequisites

1. **AWS Account**: Ensure Cost Explorer is enabled in your AWS Billing console
2. **Webhook URL**: Create a webhook in your preferred platform (Slack, Teams, Discord, etc.)
3. **Terraform**: Version 1.0 or later

## Setup Instructions

1. **Clone and navigate to the directory**:
   ```bash
   cd scripts/billing_alerts
   ```

2. **Configure variables**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your webhook URL
   ```

3. **Initialize and apply Terraform**:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## Configuration

### Webhook Setup

#### Slack
1. Go to your desired workspace settings
2. Create a new app or use an existing one
3. Enable Incoming Webhooks
4. Create a webhook for your desired channel (e.g., #aws-billing)
5. Copy the webhook URL to `terraform.tfvars`

#### Microsoft Teams
1. Go to your Teams channel
2. Click the three dots menu → Connectors
3. Add "Incoming Webhook" connector
4. Configure and copy the webhook URL

#### Discord
1. Go to your Discord server settings
2. Go to Integrations → Webhooks
3. Create a new webhook
4. Copy the webhook URL

### Schedule Customization

The default schedule is set to 9 AM JST (midnight UTC). To modify:

- Edit the `schedule_expression` in `main.tf`
- Use AWS cron format: `cron(minute hour day month ? year)`

## Cost Estimation

- **Lambda executions**: ~$0.20/month (assuming daily runs)
- **Cost Explorer API calls**: ~$0.01 per call
- **CloudWatch Logs**: Minimal cost for log storage

Total estimated cost: < $1.00/month

## Features

- Daily billing reports with total cost
- Service-wise cost breakdown (top 10 services)
- Automatic filtering of zero-cost services
- Platform-compatible formatted messages with visual blocks
- Configurable timezone support

## Security Notes

- The Lambda function requires Cost Explorer permissions
- Webhook URL is marked as sensitive in Terraform
- CloudWatch logs are retained for 14 days by default

## Troubleshooting

1. **Cost Explorer not enabled**: Enable it in AWS Billing console
2. **Lambda timeout**: Increase timeout in `main.tf` if needed
3. **Webhook errors**: Verify webhook URL and platform permissions