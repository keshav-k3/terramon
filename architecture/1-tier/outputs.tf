output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "Public subnet ID"
  value       = aws_subnet.public.id
}

output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.app.id
}

output "instance_public_ip" {
  description = "Public IP of EC2 instance"
  value       = aws_instance.app.public_ip
}

output "instance_public_dns" {
  description = "Public DNS of EC2 instance"
  value       = aws_instance.app.public_dns
}

output "security_group_id" {
  description = "Security group ID"
  value       = aws_security_group.app.id
}

output "application_url" {
  description = "Application URL"
  value       = "http://${aws_instance.app.public_ip}"
}
