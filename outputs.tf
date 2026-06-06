# =============================================================================
# UninaQuiz Infrastructure - Outputs
# =============================================================================
# Values exported after terraform apply. These are used for CI/CD
# configuration (GitHub Secrets), SSH access, and health checks.
# =============================================================================

output "ec2_public_ip" {
  description = "Public IP address of the application EC2 instance"
  value       = aws_instance.app.public_ip
}

output "ec2_instance_id" {
  description = "Instance ID of the application EC2 instance"
  value       = aws_instance.app.id
}

output "ssh_command" {
  description = "SSH command to connect to the EC2 instance"
  value       = "ssh -i uninaquiz-key.pem ec2-user@${aws_instance.app.public_ip}"
}

output "app_url" {
  description = "Base URL of the application"
  value       = "http://${aws_instance.app.public_ip}:${var.app_port}"
}

output "health_check_url" {
  description = "Health check endpoint URL"
  value       = "http://${aws_instance.app.public_ip}:${var.app_port}/api/health"
}

output "vpc_id" {
  description = "ID of the VPC created for the application"
  value       = aws_vpc.main.id
}
