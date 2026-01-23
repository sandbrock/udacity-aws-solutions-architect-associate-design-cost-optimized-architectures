variable "project_name" {
  description = "Name of the project for resource naming and tagging"
  type        = string
  default     = "task5-nat-comparison"
}

variable "environment" {
  description = "Environment name (e.g., development, production)"
  type        = string
  default     = "development"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones to use for subnets"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway solution for private subnet internet access"
  type        = bool
  default     = true
}

variable "enable_nat_instance" {
  description = "Enable NAT Instance solution for private subnet internet access"
  type        = bool
  default     = false
}

variable "nat_instance_type" {
  description = "EC2 instance type for NAT Instances (e.g., t3.nano)"
  type        = string
  default     = "t3.nano"
}

variable "nat_instance_ami_owner" {
  description = "Owner ID for Amazon Linux 2023 AMI (default: amazon)"
  type        = string
  default     = "amazon"
}

variable "enable_cloudwatch_alarms" {
  description = "Enable CloudWatch alarms for NAT Instance health monitoring"
  type        = bool
  default     = true
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
