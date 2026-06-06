# =============================================================================
# UninaQuiz Infrastructure - EC2 Instance & Key Pair
# =============================================================================
# Provisions the EC2 instance that runs the Go backend binary.
# Includes SSH key generation, AMI lookup, and a user-data script
# that prepares the server (creates app user, directories, systemd
# service, and environment file template).
# =============================================================================

# -----------------------------------------------------------------------------
# TLS Private Key
# Generates an RSA 4096-bit key pair for SSH access to the instance.
# The private key is stored locally; the public key is registered in AWS.
# -----------------------------------------------------------------------------
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# -----------------------------------------------------------------------------
# AWS Key Pair
# Registers the public half of the generated key with AWS so that
# EC2 can inject it into the instance's authorized_keys.
# -----------------------------------------------------------------------------
resource "aws_key_pair" "app" {
  key_name   = "${var.project_name}-key"
  public_key = tls_private_key.ssh.public_key_openssh

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Local File: Private Key
# Saves the private key to disk so it can be used for SSH access.
# File permissions are set to 0400 (owner read-only) for security.
# -----------------------------------------------------------------------------
resource "local_file" "private_key" {
  content         = tls_private_key.ssh.private_key_pem
  filename        = "${path.module}/uninaquiz-key.pem"
  file_permission = "0400"
}

# -----------------------------------------------------------------------------
# Data Source: Amazon Linux 2023 AMI
# Finds the latest Amazon Linux 2023 AMI owned by Amazon.
# Uses filters to match the correct architecture (x86_64).
# -----------------------------------------------------------------------------
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# -----------------------------------------------------------------------------
# EC2 Instance
# The application server running the compiled Go binary.
# User data bootstraps the instance with the required user, directory
# structure, environment file, and systemd service definition.
# -----------------------------------------------------------------------------
resource "aws_instance" "app" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.app.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  key_name                    = aws_key_pair.app.key_name
  associate_public_ip_address = true

  # Root volume: 20 GB gp3 for adequate storage and IOPS
  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true

    tags = merge(local.common_tags, {
      Name = "${var.project_name}-root-volume"
    })
  }

  # ---------------------------------------------------------------------------
  # User Data Script
  # Runs once at first boot to prepare the instance:
  #   1. System update
  #   2. Application user creation (non-login for security)
  #   3. Application directory and environment file
  #   4. Systemd service definition for automatic start/restart
  # ---------------------------------------------------------------------------
  user_data = <<-EOF
    #!/bin/bash
    set -euxo pipefail

    # --------------------------------------------------
    # 1. Update system packages
    # --------------------------------------------------
    dnf update -y

    # --------------------------------------------------
    # 2. Create a dedicated non-login user for the app
    # --------------------------------------------------
    useradd -r -s /sbin/nologin appuser || true

    # --------------------------------------------------
    # 3. Create application directory
    # --------------------------------------------------
    mkdir -p /opt/uninaquiz
    chown appuser:appuser /opt/uninaquiz

    # --------------------------------------------------
    # 4. Create environment file template
    #    Fill in the values after deployment via SSH or
    #    a secrets manager.
    # --------------------------------------------------
    cat > /opt/uninaquiz/.env << 'ENVFILE'
    # =============================================================
    # UninaQuiz Backend - Environment Variables
    # =============================================================
    # Fill in the values below and restart the service:
    #   sudo systemctl restart uninaquiz
    # =============================================================

    # PostgreSQL connection string (Supabase)
    # DATABASE_URL=postgresql://user:password@host:5432/dbname

    # Supabase project URL
    # SUPABASE_URL=https://your-project.supabase.co

    # Supabase anonymous/service key
    # SUPABASE_KEY=your-supabase-key

    # Application port (must match the security group ingress rule)
    APP_PORT=8080

    # Gin framework execution mode
    GIN_MODE=release
    ENVFILE

    # Remove leading whitespace from the .env file
    sed -i 's/^    //' /opt/uninaquiz/.env

    chown appuser:appuser /opt/uninaquiz/.env
    chmod 600 /opt/uninaquiz/.env

    # --------------------------------------------------
    # 5. Create systemd service file
    # --------------------------------------------------
    cat > /etc/systemd/system/uninaquiz.service << 'SERVICEFILE'
    [Unit]
    Description=UninaQuiz Backend API
    After=network.target

    [Service]
    Type=simple
    User=appuser
    Group=appuser
    WorkingDirectory=/opt/uninaquiz
    ExecStart=/opt/uninaquiz/uninaquiz-backend
    EnvironmentFile=/opt/uninaquiz/.env

    # Lifecycle and restart behavior
    Restart=always
    RestartSec=5s
    TimeoutStopSec=35s

    # System resource limits
    LimitNOFILE=65535

    # Sandboxing and Security Hardening
    ProtectSystem=full
    ProtectHome=true
    PrivateTmp=true
    NoNewPrivileges=true
    ProtectControlGroups=true
    ProtectKernelModules=true
    ProtectKernelTunables=true
    RestrictRealtime=true
    MemoryDenyWriteExecute=true

    # Logging and Output
    StandardOutput=journal
    StandardError=journal
    SyslogIdentifier=uninaquiz

    [Install]
    WantedBy=multi-user.target
    SERVICEFILE

    # Remove leading whitespace from the service file
    sed -i 's/^    //' /etc/systemd/system/uninaquiz.service

    # --------------------------------------------------
    # 6. Reload systemd and enable the service
    #    The service will start automatically once the
    #    binary is deployed to /opt/uninaquiz/uninaquiz-backend
    # --------------------------------------------------
    systemctl daemon-reload
    systemctl enable uninaquiz

    echo ">>> UninaQuiz instance bootstrap complete <<<"
  EOF

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-app-server"
  })

  # Prevent replacement when a newer AMI becomes available
  lifecycle {
    ignore_changes = [ami]
  }
}
