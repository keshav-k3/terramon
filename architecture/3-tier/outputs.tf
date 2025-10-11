output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs (Web Tier)"
  value       = aws_subnet.public[*].id
}

output "private_app_subnet_ids" {
  description = "Private app subnet IDs (Application Tier)"
  value       = aws_subnet.private_app[*].id
}

output "private_db_subnet_ids" {
  description = "Private db subnet IDs (Database Tier)"
  value       = aws_subnet.private_db[*].id
}

output "web_alb_dns_name" {
  description = "DNS name of the Web Tier Load Balancer"
  value       = aws_lb.web.dns_name
}

output "web_alb_arn" {
  description = "ARN of the Web Tier Load Balancer"
  value       = aws_lb.web.arn
}

output "app_alb_dns_name" {
  description = "DNS name of the Application Tier Load Balancer"
  value       = aws_lb.app.dns_name
}

output "app_alb_arn" {
  description = "ARN of the Application Tier Load Balancer"
  value       = aws_lb.app.arn
}

output "application_url" {
  description = "Application URL"
  value       = "http://${aws_lb.web.dns_name}"
}

output "web_asg_name" {
  description = "Web Tier Auto Scaling Group name"
  value       = aws_autoscaling_group.web.name
}

output "app_asg_name" {
  description = "Application Tier Auto Scaling Group name"
  value       = aws_autoscaling_group.app.name
}

output "db_endpoint" {
  description = "Database endpoint"
  value       = aws_db_instance.main.endpoint
  sensitive   = true
}

output "db_name" {
  description = "Database name"
  value       = aws_db_instance.main.db_name
}

output "db_port" {
  description = "Database port"
  value       = aws_db_instance.main.port
}

output "nat_gateway_ip" {
  description = "NAT Gateway public IP"
  value       = aws_eip.nat.public_ip
}
