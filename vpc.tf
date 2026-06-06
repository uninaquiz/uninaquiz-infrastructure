# =============================================================================
# UninaQuiz Infrastructure - VPC & Networking
# =============================================================================
# Creates the VPC, public subnet, internet gateway, and routing
# configuration needed for the EC2 instance to be publicly accessible.
# =============================================================================

# -----------------------------------------------------------------------------
# Data Source: Availability Zones
# Automatically discovers available AZs in the selected region.
# -----------------------------------------------------------------------------
data "aws_availability_zones" "available" {
  state = "available"
}

# -----------------------------------------------------------------------------
# VPC
# The main Virtual Private Cloud with DNS support enabled so that
# instances can resolve public DNS hostnames.
# -----------------------------------------------------------------------------
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-vpc"
  })
}

# -----------------------------------------------------------------------------
# Public Subnet
# Placed in the first available AZ. Instances launched here can
# receive public IPs and be reached from the internet.
# -----------------------------------------------------------------------------
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-public-subnet"
  })
}

# -----------------------------------------------------------------------------
# Internet Gateway
# Provides the VPC with a route to the public internet.
# -----------------------------------------------------------------------------
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-igw"
  })
}

# -----------------------------------------------------------------------------
# Route Table
# Defines routing rules for the public subnet, including a default
# route that sends all non-local traffic through the Internet Gateway.
# -----------------------------------------------------------------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-public-rt"
  })
}

# -----------------------------------------------------------------------------
# Route Table Association
# Links the public subnet to the public route table so that instances
# in the subnet use the IGW for outbound traffic.
# -----------------------------------------------------------------------------
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}
