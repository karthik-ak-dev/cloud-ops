output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = module.vpc.public_subnet_id
}

output "private_subnet_id" {
  description = "ID of the private subnet"
  value       = module.vpc.private_subnet_id
}

# ECR outputs
output "ecr_repository_urls" {
  description = "URLs of the ECR repositories"
  value       = var.deploy_ecr ? module.ecr[0].repository_urls : null
}

# Redis outputs
output "redis_endpoint" {
  description = "Redis primary endpoint"
  value       = var.deploy_redis ? module.redis[0].redis_endpoint : null
}

output "redis_port" {
  description = "Redis port"
  value       = var.deploy_redis ? module.redis[0].redis_port : null
}

# Aurora PostgreSQL outputs
output "aurora_cluster_endpoint" {
  description = "Aurora cluster endpoint"
  value       = var.deploy_aurora ? module.aurora_postgres[0].cluster_endpoint : null
}

output "aurora_reader_endpoint" {
  description = "Aurora reader endpoint"
  value       = var.deploy_aurora ? module.aurora_postgres[0].reader_endpoint : null
}

output "aurora_port" {
  description = "Aurora port"
  value       = var.deploy_aurora ? module.aurora_postgres[0].cluster_port : null
}

output "aurora_database_name" {
  description = "Aurora database name"
  value       = var.deploy_aurora ? module.aurora_postgres[0].database_name : null
}

output "aurora_master_username" {
  description = "Aurora master username"
  value       = var.deploy_aurora ? module.aurora_postgres[0].master_username : null
}

# EKS outputs
output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "eks_config_command" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}"
} 