variable "webhook_url" {
  description = "Webhook URL for sending billing notifications (Slack, Teams, Discord, etc.)"
  type        = string
  sensitive   = true
}