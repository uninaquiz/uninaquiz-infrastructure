# =============================================================================
# UninaQuiz Infrastructure - Main Configuration
# =============================================================================
# This file defines the Terraform and provider requirements for the
# UninaQuiz backend infrastructure on AWS.
# =============================================================================

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

# -----------------------------------------------------------------------------
# AWS Provider Configuration
# The region is configurable via the aws_region variable.
# -----------------------------------------------------------------------------
provider "aws" {
  region = var.aws_region
}

# -----------------------------------------------------------------------------
# Local Values
# Common tags applied to all resources for consistent tagging and
# easier resource management / cost allocation.
# -----------------------------------------------------------------------------
locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
