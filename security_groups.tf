# =============================================================================
# UninaQuiz Infrastructure - Security Groups
# =============================================================================
# Defines the firewall rules (security group) for the EC2 instance.
# Only SSH and the application port are open for inbound traffic.
# =============================================================================

resource "aws_security_group" "app" {
  name        = "${var.project_name}-app-sg"
  description = "Security group for the ${var.project_name} application server"
  vpc_id      = aws_vpc.main.id

  # ---------------------------------------------------------------------------
  # Ingress: SSH Access
  # Allows SSH connections from any IP address for remote administration.
  # In production, consider restricting this to specific IP ranges.
  # ---------------------------------------------------------------------------
  ingress {
    description = "Allow SSH access from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ---------------------------------------------------------------------------
  # Ingress: Application Port
  # Allows HTTP traffic on the application port so clients can reach
  # the Go backend API.
  # ---------------------------------------------------------------------------
  ingress {
    description = "Allow application traffic on port ${var.app_port}"
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ---------------------------------------------------------------------------
  # Egress: All Outbound Traffic
  # Permits the instance to make any outbound connections (e.g., to
  # Supabase, package repositories, CloudWatch).
  # ---------------------------------------------------------------------------
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-app-sg"
  })
}
