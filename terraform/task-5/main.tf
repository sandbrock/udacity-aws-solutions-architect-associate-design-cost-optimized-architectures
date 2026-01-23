terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Local values for resource tagging
locals {
  common_tags = merge(
    {
      Project     = "Task5"
      Environment = var.environment
      ManagedBy   = "Terraform"
    },
    var.common_tags
  )
}

# ===================================
# VPC Resources
# ===================================

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-vpc"
    }
  )
}

# ===================================
# Internet Gateway
# ===================================

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-igw"
    }
  )
}

# ===================================
# Public Subnets
# ===================================

resource "aws_subnet" "public" {
  count = length(var.availability_zones)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-public-subnet-${var.availability_zones[count.index]}"
      Tier = "Public"
    }
  )
}

# ===================================
# Private Subnets
# ===================================

resource "aws_subnet" "private" {
  count = length(var.availability_zones)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-private-subnet-${var.availability_zones[count.index]}"
      Tier = "Private"
    }
  )
}

# ===================================
# Public Route Table
# ===================================

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-public-rt"
    }
  )
}

resource "aws_route_table_association" "public" {
  count = length(var.availability_zones)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ===================================
# NAT Gateway Solution
# ===================================

# Elastic IPs for NAT Gateways
resource "aws_eip" "nat_gateway" {
  count = var.enable_nat_gateway ? length(var.availability_zones) : 0

  domain = "vpc"

  tags = merge(
    local.common_tags,
    {
      Name     = "${var.project_name}-nat-gateway-eip-${var.availability_zones[count.index]}"
      Solution = "NAT-Gateway"
    }
  )

  depends_on = [aws_internet_gateway.main]
}

# NAT Gateways
resource "aws_nat_gateway" "main" {
  count = var.enable_nat_gateway ? length(var.availability_zones) : 0

  allocation_id = aws_eip.nat_gateway[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(
    local.common_tags,
    {
      Name     = "${var.project_name}-nat-gateway-${var.availability_zones[count.index]}"
      Solution = "NAT-Gateway"
    }
  )

  depends_on = [aws_internet_gateway.main]
}

# Private Route Tables for NAT Gateway
resource "aws_route_table" "private_nat_gateway" {
  count = var.enable_nat_gateway ? length(var.availability_zones) : 0

  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = merge(
    local.common_tags,
    {
      Name     = "${var.project_name}-private-rt-nat-gateway-${var.availability_zones[count.index]}"
      Solution = "NAT-Gateway"
    }
  )
}

resource "aws_route_table_association" "private_nat_gateway" {
  count = var.enable_nat_gateway ? length(var.availability_zones) : 0

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private_nat_gateway[count.index].id
}
