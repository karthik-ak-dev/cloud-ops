variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# Feature flags
variable "deploy_aurora" {
  description = "Whether to deploy Aurora PostgreSQL"
  type        = bool
  default     = true
}

variable "deploy_aurora_srvless" {
  description = "Whether to deploy Aurora PostgreSQL Serverless"
  type        = bool
  default     = true
}

variable "deploy_redis" {
  description = "Whether to deploy Redis ElastiCache"
  type        = bool
  default     = true
}

variable "deploy_valkey_srvless" {
  description = "Whether to deploy Valkey Serverless"
  type        = bool
  default     = true
}

variable "deploy_ecr" {
  description = "Whether to deploy ECR repositories"
  type        = bool
  default     = true
}

variable "deploy_eks" {
  description = "Whether to deploy EKS cluster"
  type        = bool
  default     = true
}

variable "deploy_alb_controller" {
  description = "Whether to deploy AWS Load Balancer Controller"
  type        = bool
  default     = true
}

# Redis variables
variable "redis_node_type" {
  description = "ElastiCache node type"
  type        = string
  default     = "cache.t3.small"
}

variable "redis_node_count" {
  description = "Number of Redis nodes"
  type        = number
  default     = 2
}

variable "redis_auth_token" {
  description = "Auth token for Redis"
  type        = string
  sensitive   = true
}

variable "redis_engine_version" {
  description = "Redis engine version"
  type        = string
  default     = "7.0"
}

# Valkey Serverless variables
variable "valkey_srvless_max_storage_gb" {
  description = "Maximum storage in GB for Valkey Serverless"
  type        = number
  default     = 10
}

variable "valkey_srvless_max_ecpu_per_second" {
  description = "Maximum eCPU per second for Valkey Serverless"
  type        = number
  default     = 20000
}

variable "valkey_srvless_auth_token" {
  description = "Auth token for Valkey Serverless"
  type        = string
  sensitive   = true
}

# ECR variables
variable "ecr_repository_names" {
  description = "List of ECR repository names to create"
  type        = list(string)
  default     = ["services"]
}

variable "ecr_max_image_count" {
  description = "Maximum number of images to keep in each repository"
  type        = number
  default     = 30
}

variable "ecr_scan_on_push" {
  description = "Whether to scan images on push to ECR"
  type        = bool
  default     = true
}

# Aurora PostgreSQL variables
variable "postgres_instance_class" {
  description = "Instance class for Aurora PostgreSQL"
  type        = string
  default     = "db.t3.medium"
}

variable "postgres_instance_count" {
  description = "Number of Aurora PostgreSQL instances"
  type        = number
  default     = 2
}

variable "postgres_engine_version" {
  description = "Engine version for Aurora PostgreSQL"
  type        = string
  default     = "16.6"
}

variable "postgres_database_name" {
  description = "Name of the initial database to create"
  type        = string
  default     = "postgresdb"
}

variable "postgres_master_username" {
  description = "Master username for the database"
  type        = string
  default     = "postgres"
}

variable "postgres_master_password" {
  description = "Master password for the database"
  type        = string
  sensitive   = true
}

variable "postgres_deletion_protection" {
  description = "Whether deletion protection is enabled for the Aurora PostgreSQL cluster"
  type        = bool
  default     = true
}

variable "postgres_skip_final_snapshot" {
  description = "Whether to skip the final snapshot when deleting the Aurora PostgreSQL cluster"
  type        = bool
  default     = false
}

# Aurora PostgreSQL Serverless variables
variable "postgres_srvless_engine_version" {
  description = "Engine version for Aurora PostgreSQL Serverless"
  type        = string
  default     = "16.6"
}

variable "postgres_srvless_database_name" {
  description = "Name of the initial database to create"
  type        = string
  default     = "postgresdb"
}

variable "postgres_srvless_master_username" {
  description = "Master username for the database"
  type        = string
  default     = "postgres"
}

variable "postgres_srvless_master_password" {
  description = "Master password for the database"
  type        = string
  sensitive   = true
}

variable "postgres_srvless_deletion_protection" {
  description = "Whether deletion protection is enabled for the Aurora PostgreSQL Serverless cluster"
  type        = bool
  default     = true
}

variable "postgres_srvless_skip_final_snapshot" {
  description = "Whether to skip the final snapshot when deleting the Aurora PostgreSQL Serverless cluster"
  type        = bool
  default     = false
}

variable "postgres_srvless_auto_pause" {
  description = "Whether to enable auto pause for the Aurora Serverless cluster"
  type        = bool
  default     = true
}

variable "postgres_srvless_max_capacity" {
  description = "Maximum Aurora capacity unit for the Aurora Serverless cluster"
  type        = number
  default     = 4
}

variable "postgres_srvless_min_capacity" {
  description = "Minimum Aurora capacity unit for the Aurora Serverless cluster"
  type        = number
  default     = 1
}

variable "postgres_srvless_seconds_until_auto_pause" {
  description = "Seconds of no activity before the Aurora Serverless cluster is paused"
  type        = number
  default     = 300
}

variable "postgres_srvless_timeout_action" {
  description = "Action to take when a scaling event times out"
  type        = string
  default     = "RollbackCapacityChange"
}

# EKS variables
variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.33"
}

variable "eks_instance_type" {
  description = "Instance type for the EKS nodes"
  type        = string
  default     = "t3.medium"
}

variable "eks_desired_capacity" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "eks_max_capacity" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 4
}

variable "eks_min_capacity" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

# CI/CD variables
variable "create_ci_user" {
  description = "Whether to create IAM user for CI to push to ECR"
  type        = bool
  default     = true
}

variable "create_cd_user" {
  description = "Whether to create IAM user for CD to deploy to EKS"
  type        = bool
  default     = true
}

variable "create_access_keys" {
  description = "Whether to create access keys for the users (warning: keys will be stored in state)"
  type        = bool
  default     = true
}

variable "environment" {
  description = "Environment name (used for resource naming and tagging)"
  type        = string
  default     = "dev"
}

variable "enable_cloudflare_ip_restriction" {
  description = "Whether to restrict ALB access to Cloudflare IP ranges only (recommended for production with Cloudflare)"
  type        = bool
  default     = false
} 