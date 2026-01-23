# AWS Region Configuration
variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

# Cost Allocation Tags
variable "environment" {
  description = "Environment name (e.g., QA, Development, Staging, Production)"
  type        = string
  default     = "QA"
}

variable "team" {
  description = "Team name responsible for the resource (e.g., Engineering, QA, DevOps)"
  type        = string
  default     = "Engineering"
}

variable "project" {
  description = "Project name or application identifier"
  type        = string
  default     = "qa-instance-1"
}

# EC2 Instance Configuration
variable "instance_type" {
  description = "EC2 instance type (T3 recommended for burstable performance)"
  type        = string
  default     = "t3.medium"

  validation {
    condition     = can(regex("^t3\\.", var.instance_type))
    error_message = "Instance type must be from the T3 family (e.g., t3.micro, t3.small, t3.medium) for cost optimization."
  }
}

variable "instance_name" {
  description = "Name tag for the EC2 instance"
  type        = string
  default     = "qa-instance-1"
}

variable "custom_ami_id" {
  description = "Custom AMI ID to use for the instance. If empty, the latest Amazon Linux 2023 AMI will be used."
  type        = string
  default     = ""
}

# Network Configuration
variable "vpc_id" {
  description = "VPC ID where the instance will be launched"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID where the instance will be launched"
  type        = string
}

# SSH Access Configuration
variable "key_pair_name" {
  description = "Name of the SSH key pair to associate with the instance"
  type        = string
}

variable "ssh_cidr_blocks" {
  description = "CIDR blocks allowed to SSH into the instance"
  type        = list(string)
  default     = []
}

# HTTP/HTTPS Access Configuration
variable "enable_http_access" {
  description = "Enable HTTP (port 80) access to the instance"
  type        = bool
  default     = false
}

variable "http_cidr_blocks" {
  description = "CIDR blocks allowed HTTP access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enable_https_access" {
  description = "Enable HTTPS (port 443) access to the instance"
  type        = bool
  default     = false
}

variable "https_cidr_blocks" {
  description = "CIDR blocks allowed HTTPS access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# Custom Security Group Rules
variable "custom_ingress_rules" {
  description = "List of custom ingress rules for the security group"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = []
}

# EBS Volume Configuration
variable "root_volume_type" {
  description = "EBS volume type for root volume (gp3 recommended for cost optimization)"
  type        = string
  default     = "gp3"

  validation {
    condition     = contains(["gp3", "gp2", "io1", "io2"], var.root_volume_type)
    error_message = "Volume type must be gp3, gp2, io1, or io2. gp3 is recommended for cost optimization."
  }
}

variable "root_volume_size" {
  description = "Size of the root EBS volume in GB"
  type        = number
  default     = 20

  validation {
    condition     = var.root_volume_size >= 8 && var.root_volume_size <= 16384
    error_message = "Root volume size must be between 8 and 16384 GB."
  }
}

variable "enable_ebs_encryption" {
  description = "Enable EBS encryption for the root volume"
  type        = bool
  default     = true
}

# IAM Configuration (Optional)
variable "iam_instance_profile_name" {
  description = "IAM instance profile name to attach to the instance (optional, for SSM or other AWS service access)"
  type        = string
  default     = ""
}

# Monitoring Configuration
variable "enable_detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring (additional cost)"
  type        = bool
  default     = false
}

# User Data Script (Optional)
variable "user_data_script" {
  description = "User data script to run on instance launch (optional)"
  type        = string
  default     = ""
}
