# EC2 Instance Outputs
output "instance_id" {
  description = "The ID of the EC2 instance"
  value       = aws_instance.qa_instance.id
}

output "instance_arn" {
  description = "The ARN of the EC2 instance"
  value       = aws_instance.qa_instance.arn
}

output "instance_state" {
  description = "The current state of the EC2 instance"
  value       = aws_instance.qa_instance.instance_state
}

output "instance_type" {
  description = "The instance type of the EC2 instance"
  value       = aws_instance.qa_instance.instance_type
}

# Network Outputs
output "private_ip" {
  description = "The private IP address of the EC2 instance"
  value       = aws_instance.qa_instance.private_ip
}

output "public_ip" {
  description = "The public IP address of the EC2 instance (if assigned)"
  value       = aws_instance.qa_instance.public_ip
}

output "availability_zone" {
  description = "The availability zone where the instance is running"
  value       = aws_instance.qa_instance.availability_zone
}

output "subnet_id" {
  description = "The subnet ID where the instance is running"
  value       = aws_instance.qa_instance.subnet_id
}

# Security Group Outputs
output "security_group_id" {
  description = "The ID of the security group attached to the instance"
  value       = aws_security_group.qa_instance.id
}

output "security_group_name" {
  description = "The name of the security group attached to the instance"
  value       = aws_security_group.qa_instance.name
}

# Volume Outputs
output "root_volume_id" {
  description = "The ID of the root EBS volume"
  value       = aws_instance.qa_instance.root_block_device[0].volume_id
}

output "root_volume_type" {
  description = "The type of the root EBS volume"
  value       = aws_instance.qa_instance.root_block_device[0].volume_type
}

output "root_volume_size" {
  description = "The size of the root EBS volume in GB"
  value       = aws_instance.qa_instance.root_block_device[0].volume_size
}

# AMI Output
output "ami_id" {
  description = "The AMI ID used to launch the instance"
  value       = aws_instance.qa_instance.ami
}

# Tags Output
output "tags" {
  description = "All tags applied to the EC2 instance"
  value       = aws_instance.qa_instance.tags_all
}

# SSH Connection Information
output "ssh_connection_command" {
  description = "SSH command to connect to the instance (requires private key)"
  value       = aws_instance.qa_instance.public_ip != "" ? "ssh -i /path/to/${var.key_pair_name}.pem ec2-user@${aws_instance.qa_instance.public_ip}" : "ssh -i /path/to/${var.key_pair_name}.pem ec2-user@${aws_instance.qa_instance.private_ip}"
}
