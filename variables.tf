# =============================================================================
# UninaQuiz Infrastructure - Variable Definitions
# =============================================================================
# All configurable parameters for the infrastructure are defined here.
# Override defaults via terraform.tfvars or -var flags.
# =============================================================================

variable "aws_region" {
  description = "AWS region where all resources will be provisioned"
  type        = string
  default     = "us-east-2"
}

variable "project_name" {
  description = "Name of the project, used for resource naming and tagging"
  type        = string
  default     = "uninaquiz"
}

variable "instance_type" {
  description = "EC2 instance type for the application server"
  type        = string
  default     = "t2.micro"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet where the EC2 instance resides"
  type        = string
  default     = "10.0.1.0/24"
}

variable "app_port" {
  description = "Port on which the Go backend application listens"
  type        = number
  default     = 8080
}

variable "environment" {
  description = "Deployment environment (e.g., production, staging, development)"
  type        = string
  default     = "production"
}
