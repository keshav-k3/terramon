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
  region = "ap-northeast-1"
}

# IAM role for Lambda function
resource "aws_iam_role" "billing_alert_lambda_role" {
  name = "billing-alert-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM policy for Cost Explorer access
resource "aws_iam_policy" "billing_alert_policy" {
  name        = "billing-alert-policy"
  description = "Policy for Lambda to access Cost Explorer and CloudWatch Logs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ce:GetCostAndUsage",
          "ce:GetDimensionValues",
          "ce:GetReservationCoverage",
          "ce:GetReservationPurchaseRecommendation",
          "ce:GetReservationUtilization",
          "ce:GetUsageReport"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "billing_alert_policy_attachment" {
  role       = aws_iam_role.billing_alert_lambda_role.name
  policy_arn = aws_iam_policy.billing_alert_policy.arn
}

# Lambda function
resource "aws_lambda_function" "billing_alert" {
  filename         = "billing_alert.zip"
  function_name    = "aws-billing-alert"
  role            = aws_iam_role.billing_alert_lambda_role.arn
  handler         = "lambda_function.lambda_handler"
  runtime         = "python3.11"
  timeout         = 60

  environment {
    variables = {
      WEBHOOK_URL = var.webhook_url
      TIMEZONE         = "Asia/Tokyo"
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.billing_alert_policy_attachment,
    aws_cloudwatch_log_group.billing_alert_logs,
    data.archive_file.lambda_zip
  ]
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "billing_alert_logs" {
  name              = "/aws/lambda/aws-billing-alert"
  retention_in_days = 14
}

# EventBridge rule for daily schedule
resource "aws_cloudwatch_event_rule" "billing_alert_schedule" {
  name                = "billing-alert-daily"
  description         = "Trigger billing alert Lambda daily at 9 AM JST"
  schedule_expression = "cron(0 0 * * ? *)"  # 9 AM JST = 0 AM UTC
}

# EventBridge target
resource "aws_cloudwatch_event_target" "billing_alert_target" {
  rule      = aws_cloudwatch_event_rule.billing_alert_schedule.name
  target_id = "BillingAlertLambdaTarget"
  arn       = aws_lambda_function.billing_alert.arn
}

# Lambda permission for EventBridge
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.billing_alert.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.billing_alert_schedule.arn
}

# Create Lambda deployment package
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda_function.py"
  output_path = "${path.module}/billing_alert.zip"
}