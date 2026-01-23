terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      ManagedBy   = "Terraform"
      Environment = var.environment
      Team        = var.team
      Project     = var.project
    }
  }
}

# Data source to get latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  count       = var.custom_ami_id == "" ? 1 : 0
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
    name   = "root-device-type"
    values = ["ebs"]
  }
}

# Security Group for EC2 Instance
resource "aws_security_group" "qa_instance" {
  name_prefix = "${var.project}-sg-"
  description = "Security group for ${var.project} QA instance"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project}-qa-security-group"
  }
}

# Security Group Rules - SSH Access
resource "aws_security_group_rule" "ssh_ingress" {
  count             = length(var.ssh_cidr_blocks) > 0 ? 1 : 0
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.ssh_cidr_blocks
  security_group_id = aws_security_group.qa_instance.id
  description       = "SSH access from specified CIDR blocks"
}

# Security Group Rules - HTTP Access (Optional)
resource "aws_security_group_rule" "http_ingress" {
  count             = var.enable_http_access ? 1 : 0
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = var.http_cidr_blocks
  security_group_id = aws_security_group.qa_instance.id
  description       = "HTTP access from specified CIDR blocks"
}

# Security Group Rules - HTTPS Access (Optional)
resource "aws_security_group_rule" "https_ingress" {
  count             = var.enable_https_access ? 1 : 0
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = var.https_cidr_blocks
  security_group_id = aws_security_group.qa_instance.id
  description       = "HTTPS access from specified CIDR blocks"
}

# Security Group Rules - Custom Ingress Rules
resource "aws_security_group_rule" "custom_ingress" {
  for_each = { for idx, rule in var.custom_ingress_rules : idx => rule }

  type              = "ingress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = each.value.cidr_blocks
  security_group_id = aws_security_group.qa_instance.id
  description       = each.value.description
}

# Security Group Rules - Egress (Allow all outbound)
resource "aws_security_group_rule" "egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.qa_instance.id
  description       = "Allow all outbound traffic"
}

# EC2 Instance - Cost-Optimized QA Instance
resource "aws_instance" "qa_instance" {
  ami           = var.custom_ami_id != "" ? var.custom_ami_id : data.aws_ami.amazon_linux_2023[0].id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id
  key_name      = var.key_pair_name

  vpc_security_group_ids = [aws_security_group.qa_instance.id]
  iam_instance_profile   = var.iam_instance_profile_name

  # Root volume configuration - gp3 for cost optimization
  root_block_device {
    volume_type           = var.root_volume_type
    volume_size           = var.root_volume_size
    delete_on_termination = true
    encrypted             = var.enable_ebs_encryption

    tags = {
      Name = "${var.project}-qa-root-volume"
    }
  }

  # Enable detailed monitoring if specified
  monitoring = var.enable_detailed_monitoring

  # User data for initial setup (optional)
  user_data = var.user_data_script

  tags = {
    Name = var.instance_name
  }

  lifecycle {
    create_before_destroy = false
  }
}
