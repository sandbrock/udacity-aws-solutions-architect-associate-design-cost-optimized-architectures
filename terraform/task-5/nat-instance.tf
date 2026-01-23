# ===================================
# NAT Instance Solution
# ===================================

# Data source for latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = [var.nat_instance_ami_owner]

  filter {
    name   = "name"
    values = ["al2023-ami-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Security Group for NAT Instances
resource "aws_security_group" "nat_instance" {
  count = var.enable_nat_instance ? 1 : 0

  name        = "${var.project_name}-nat-instance-sg"
  description = "Security group for NAT Instances to allow traffic from private subnets"
  vpc_id      = aws_vpc.main.id

  # Allow all traffic from private subnets
  dynamic "ingress" {
    for_each = var.private_subnet_cidrs
    content {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = [ingress.value]
      description = "Allow all traffic from private subnet ${ingress.value}"
    }
  }

  # Allow all outbound traffic to the internet
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(
    local.common_tags,
    {
      Name     = "${var.project_name}-nat-instance-sg"
      Solution = "NAT-Instance"
    }
  )
}

# IAM Role for NAT Instances
resource "aws_iam_role" "nat_instance" {
  count = var.enable_nat_instance ? 1 : 0

  name = "${var.project_name}-nat-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name     = "${var.project_name}-nat-instance-role"
      Solution = "NAT-Instance"
    }
  )
}

# Attach CloudWatch Agent Server Policy for monitoring
resource "aws_iam_role_policy_attachment" "nat_instance_cloudwatch" {
  count = var.enable_nat_instance ? 1 : 0

  role       = aws_iam_role.nat_instance[0].name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# IAM Instance Profile for NAT Instances
resource "aws_iam_instance_profile" "nat_instance" {
  count = var.enable_nat_instance ? 1 : 0

  name = "${var.project_name}-nat-instance-profile"
  role = aws_iam_role.nat_instance[0].name

  tags = merge(
    local.common_tags,
    {
      Name     = "${var.project_name}-nat-instance-profile"
      Solution = "NAT-Instance"
    }
  )
}

# NAT Instances
resource "aws_instance" "nat_instance" {
  count = var.enable_nat_instance ? length(var.availability_zones) : 0

  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.nat_instance_type
  subnet_id              = aws_subnet.public[count.index].id
  vpc_security_group_ids = [aws_security_group.nat_instance[0].id]
  iam_instance_profile   = aws_iam_instance_profile.nat_instance[0].name
  source_dest_check      = false

  user_data = file("${path.module}/user-data.sh")

  tags = merge(
    local.common_tags,
    {
      Name     = "${var.project_name}-nat-instance-${var.availability_zones[count.index]}"
      Solution = "NAT-Instance"
    }
  )

  # Ensure proper resource creation order
  depends_on = [
    aws_security_group.nat_instance,
    aws_iam_instance_profile.nat_instance
  ]
}

# Private Route Tables for NAT Instance
resource "aws_route_table" "private_nat_instance" {
  count = var.enable_nat_instance && !var.enable_nat_gateway ? length(var.availability_zones) : 0

  vpc_id = aws_vpc.main.id

  route {
    cidr_block           = "0.0.0.0/0"
    network_interface_id = aws_instance.nat_instance[count.index].primary_network_interface_id
  }

  tags = merge(
    local.common_tags,
    {
      Name     = "${var.project_name}-private-rt-nat-instance-${var.availability_zones[count.index]}"
      Solution = "NAT-Instance"
    }
  )
}

resource "aws_route_table_association" "private_nat_instance" {
  count = var.enable_nat_instance && !var.enable_nat_gateway ? length(var.availability_zones) : 0

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private_nat_instance[count.index].id
}

# ===================================
# CloudWatch Alarms for NAT Instances
# ===================================

resource "aws_cloudwatch_metric_alarm" "nat_instance_status_check" {
  count = var.enable_nat_instance && var.enable_cloudwatch_alarms ? length(var.availability_zones) : 0

  alarm_name          = "${var.project_name}-nat-instance-status-check-${var.availability_zones[count.index]}"
  alarm_description   = "Triggers when NAT Instance ${var.availability_zones[count.index]} fails status checks"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Maximum"
  threshold           = 1
  treat_missing_data  = "breaching"

  dimensions = {
    InstanceId = aws_instance.nat_instance[count.index].id
  }

  tags = merge(
    local.common_tags,
    {
      Name     = "${var.project_name}-nat-instance-alarm-${var.availability_zones[count.index]}"
      Solution = "NAT-Instance"
    }
  )
}
