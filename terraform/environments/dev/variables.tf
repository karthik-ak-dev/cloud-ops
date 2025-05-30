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

variable "deploy_redis" {
  description = "Whether to deploy Redis ElastiCache"
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

# ECR variables
variable "ecr_repository_names" {
  description = "List of ECR repository names to create"
  type        = list(string)
  default     = ["api", "frontend", "worker"]
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
  default     = "13.7"
}

variable "postgres_database_name" {
  description = "Name of the initial database to create"
  type        = string
  default     = "postgres-db"
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

# EKS variables
variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
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