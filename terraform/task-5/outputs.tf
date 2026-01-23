# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

# Subnet Outputs
output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "public_subnet_cidrs" {
  description = "List of public subnet CIDR blocks"
  value       = aws_subnet.public[*].cidr_block
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "private_subnet_cidrs" {
  description = "List of private subnet CIDR blocks"
  value       = aws_subnet.private[*].cidr_block
}

# NAT Gateway Outputs
output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs (if NAT Gateway is enabled)"
  value       = var.enable_nat_gateway ? aws_nat_gateway.main[*].id : []
}

output "nat_gateway_public_ips" {
  description = "List of Elastic IP addresses allocated to NAT Gateways"
  value       = var.enable_nat_gateway ? aws_eip.nat_gateway[*].public_ip : []
}

# NAT Instance Outputs
output "nat_instance_ids" {
  description = "List of NAT Instance IDs (if NAT Instance is enabled)"
  value       = var.enable_nat_instance ? aws_instance.nat_instance[*].id : []
}

output "nat_instance_private_ips" {
  description = "List of NAT Instance private IP addresses"
  value       = var.enable_nat_instance ? aws_instance.nat_instance[*].private_ip : []
}

output "nat_instance_public_ips" {
  description = "List of NAT Instance public IP addresses"
  value       = var.enable_nat_instance ? aws_instance.nat_instance[*].public_ip : []
}

# Route Table Outputs
output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "List of private route table IDs"
  value = concat(
    var.enable_nat_gateway ? aws_route_table.private_nat_gateway[*].id : [],
    var.enable_nat_instance ? aws_route_table.private_nat_instance[*].id : []
  )
}
