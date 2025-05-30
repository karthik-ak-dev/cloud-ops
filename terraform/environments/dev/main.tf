# S3 backend configuration - Terraform state is stored here
terraform {
  backend "s3" {
    bucket         = "dev-client-name-terraform-state"
    key            = "dev/terraform.tfstate"
    region         = "eu-west-3"
    encrypt        = true
    dynamodb_table = "terraform-state-locks-ddb"
  }
}

# Import provider versions from the providers module
module "providers" {
  source = "../../modules/providers"
}

# AWS provider configuration
provider "aws" {
  region = var.region
}

# Phase 1: Create AWS infrastructure
# VPC is required by most other resources
module "vpc" {
  source = "../../modules/vpc"

  project_name     = var.project_name
  vpc_cidr         = var.vpc_cidr
  region           = var.region
  eks_cluster_name = "${var.project_name}-eks-cluster"
}

# Optional: Create ECR repositories if enabled
module "ecr" {
  count  = var.deploy_ecr ? 1 : 0
  source = "../../modules/ecr"

  project_name       = var.project_name
  repository_names   = var.ecr_repository_names
  max_image_count    = var.ecr_max_image_count
  scan_on_push       = var.ecr_scan_on_push
}

# Optional: Create Redis ElastiCache if enabled
module "redis" {
  count  = var.deploy_redis ? 1 : 0
  source = "../../modules/redis"

  project_name      = var.project_name
  vpc_id            = module.vpc.vpc_id
  vpc_cidr          = var.vpc_cidr
  private_subnet_ids = module.vpc.private_subnet_ids
  node_type         = var.redis_node_type
  node_count        = var.redis_node_count
  auth_token        = var.redis_auth_token

  depends_on = [module.vpc]
}

# Optional: Create Aurora PostgreSQL if enabled
module "aurora_postgres" {
  count  = var.deploy_aurora ? 1 : 0
  source = "../../modules/aurora-postgres"

  project_name       = var.project_name
  vpc_id             = module.vpc.vpc_id
  vpc_cidr           = var.vpc_cidr
  private_subnet_ids = module.vpc.private_subnet_ids
  
  instance_class    = var.postgres_instance_class
  instance_count    = var.postgres_instance_count
  engine_version    = var.postgres_engine_version
  database_name     = var.postgres_database_name
  master_username   = var.postgres_master_username
  master_password   = var.postgres_master_password
  
  availability_zones = ["${var.region}a", "${var.region}b"]

  depends_on = [module.vpc]
}

# Optional: Create EKS cluster if enabled
module "eks" {
  count  = var.deploy_eks ? 1 : 0
  source = "../../modules/eks"

  project_name       = var.project_name
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids
  kubernetes_version = var.kubernetes_version
  instance_type      = var.eks_instance_type
  desired_capacity   = var.eks_desired_capacity
  max_capacity       = var.eks_max_capacity
  min_capacity       = var.eks_min_capacity

  depends_on = [module.vpc]
}

# Create locals for EKS outputs or empty values if EKS is not deployed
locals {
  eks_cluster_endpoint = var.deploy_eks ? (length(module.eks) > 0 ? module.eks[0].cluster_endpoint : "") : ""
  eks_cluster_certificate_authority_data = var.deploy_eks ? (length(module.eks) > 0 ? module.eks[0].cluster_certificate_authority_data : "") : ""
  eks_cluster_name = var.deploy_eks ? (length(module.eks) > 0 ? module.eks[0].cluster_name : "") : ""
}

# Phase 2: Configure Kubernetes and Helm providers for EKS-dependent resources

# Conditional Kubernetes provider configuration
provider "kubernetes" {
  host                   = local.eks_cluster_endpoint
  cluster_ca_certificate = local.eks_cluster_certificate_authority_data != "" ? base64decode(local.eks_cluster_certificate_authority_data) : null
  
  dynamic "exec" {
    for_each = local.eks_cluster_name != "" ? [1] : []
    content {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", local.eks_cluster_name]
      command     = "aws"
    }
  }
  
  # Skip this provider configuration when EKS is not deployed
  alias = "eks"
}

# Conditional Helm provider configuration
provider "helm" {
  kubernetes {
    host                   = local.eks_cluster_endpoint
    cluster_ca_certificate = local.eks_cluster_certificate_authority_data != "" ? base64decode(local.eks_cluster_certificate_authority_data) : null
    
    dynamic "exec" {
      for_each = local.eks_cluster_name != "" ? [1] : []
      content {
        api_version = "client.authentication.k8s.io/v1beta1"
        args        = ["eks", "get-token", "--cluster-name", local.eks_cluster_name]
        command     = "aws"
      }
    }
  }
  
  # Skip this provider configuration when EKS is not deployed
  alias = "eks"
}

# Phase 3: Deploy EKS-dependent resources

# Optional: Deploy ALB controller if enabled (and if EKS is enabled)
module "alb_controller" {
  count  = var.deploy_eks && var.deploy_alb_controller ? 1 : 0
  source = "../../modules/alb-controller"

  iam_role_arn  = module.eks[0].aws_load_balancer_controller_role_arn
  cluster_name  = module.eks[0].cluster_name
  region        = var.region
  vpc_id        = module.vpc.vpc_id

  # Explicitly pass providers to the module
  providers = {
    kubernetes = kubernetes.eks
    helm       = helm.eks
  }

  depends_on = [module.eks]
} 