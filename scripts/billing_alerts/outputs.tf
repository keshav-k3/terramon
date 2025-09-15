output "lambda_function_name" {
  description = "Name of the billing alert Lambda function"
  value       = aws_lambda_function.billing_alert.function_name
}

output "lambda_function_arn" {
  description = "ARN of the billing alert Lambda function"
  value       = aws_lambda_function.billing_alert.arn
}

output "eventbridge_rule_name" {
  description = "Name of the EventBridge rule for daily scheduling"
  value       = aws_cloudwatch_event_rule.billing_alert_schedule.name
}