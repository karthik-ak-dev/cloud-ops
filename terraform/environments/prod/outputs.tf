output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnet_ids
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
  value       = var.deploy_eks ? module.platform.cluster_endpoint : null
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = var.deploy_eks ? module.platform.cluster_name : null
}

output "eks_config_command" {
  description = "Command to configure kubectl"
  value       = var.deploy_eks && module.platform.cluster_name != null ? "aws eks update-kubeconfig --region ${var.region} --name ${module.platform.cluster_name}" : "EKS cluster not deployed"
}

# CI/CD Outputs
output "ci_user_name" {
  description = "Name of the IAM user for CI to push to ECR"
  value       = module.ci_cd.ci_user_name
}

output "ci_access_key_id" {
  description = "Access key ID for the CI user"
  value       = module.ci_cd.ci_access_key_id
  sensitive   = true
}

output "ci_secret_access_key" {
  description = "Secret access key for the CI user"
  value       = module.ci_cd.ci_secret_access_key
  sensitive   = true
}

output "cd_user_name" {
  description = "Name of the IAM user for CD to deploy to EKS"
  value       = module.ci_cd.cd_user_name
}

output "cd_access_key_id" {
  description = "Access key ID for the CD user"
  value       = module.ci_cd.cd_access_key_id
  sensitive   = true
}

output "cd_secret_access_key" {
  description = "Secret access key for the CD user"
  value       = module.ci_cd.cd_secret_access_key
  sensitive   = true
}

output "platform_ready" {
  description = "Indicates if the complete platform is ready for application deployment"
  value       = var.deploy_eks ? module.platform.platform_ready : false
}

output "alb_controller_deployed" {
  description = "Whether ALB controller was deployed"
  value       = var.deploy_eks ? module.platform.alb_controller_deployed : false
}

output "alb_controller_helm_status" {
  description = "Status of ALB controller Helm release"
  value       = var.deploy_eks ? module.platform.alb_controller_helm_status : null
}

output "alb_security_group_id" {
  description = "ID of the ALB security group (use in ingress annotations)"
  value       = var.deploy_eks ? module.platform.alb_security_group_id : null
} 