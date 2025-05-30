output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

# Accessing specific subnets if needed
output "private_subnet_id_1" {
  description = "ID of the first private subnet"
  value       = length(aws_subnet.private) > 0 ? aws_subnet.private[0].id : null
}

output "private_subnet_id_2" {
  description = "ID of the second private subnet"
  value       = length(aws_subnet.private) > 1 ? aws_subnet.private[1].id : null
}

output "public_subnet_cidrs" {
  description = "CIDR blocks of the public subnets"
  value       = aws_subnet.public[*].cidr_block
}

output "private_subnet_cidrs" {
  description = "CIDR blocks of the private subnets"
  value       = aws_subnet.private[*].cidr_block
}

# Accessing specific subnet CIDRs if needed
output "private_subnet_cidr_1" {
  description = "CIDR block of the first private subnet"
  value       = length(aws_subnet.private) > 0 ? aws_subnet.private[0].cidr_block : null
}

output "private_subnet_cidr_2" {
  description = "CIDR block of the second private subnet"
  value       = length(aws_subnet.private) > 1 ? aws_subnet.private[1].cidr_block : null
} 