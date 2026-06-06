# =============================================================================
# UninaQuiz Infrastructure - IAM Configuration
# =============================================================================
# Creates the IAM role, policy, and instance profile that the EC2
# instance assumes. Follows the principle of least privilege, granting
# only CloudWatch Logs and SSM Parameter Store read access.
# =============================================================================

# -----------------------------------------------------------------------------
# IAM Role
# The role that the EC2 instance assumes via the instance profile.
# The trust policy allows only the EC2 service to assume this role.
# -----------------------------------------------------------------------------
resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# IAM Policy
# Minimal permissions for the application:
# - CloudWatch Logs: Create log groups/streams and push log events
# - SSM Parameter Store: Read parameters (for secrets management)
# -----------------------------------------------------------------------------
resource "aws_iam_policy" "ec2_policy" {
  name        = "${var.project_name}-ec2-policy"
  description = "Minimal permissions for ${var.project_name} EC2 instance (CloudWatch Logs + SSM read)"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Resource = "*"
      }
    ]
  })

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Policy Attachment
# Binds the custom policy to the EC2 role.
# -----------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "ec2_policy_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ec2_policy.arn
}

# -----------------------------------------------------------------------------
# Instance Profile
# The instance profile is what actually gets attached to the EC2
# instance, linking it to the IAM role.
# -----------------------------------------------------------------------------
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2_role.name

  tags = local.common_tags
}
