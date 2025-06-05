# ====================================================================
# CLEAN ENVIRONMENT CONFIGURATION - PROD
# ====================================================================
# This file demonstrates the improved architecture where:
# - Environment files are clean and simple
# - Provider configuration is handled in modules
# - Complex logic is abstracted away
# - State tracking is internal to modules
# ====================================================================

# Terraform and provider version requirements
terraform {
  required_version = ">= 1.0.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.37"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17"
    }
  }

  # S3 backend configuration - Terraform state is stored here
  backend "s3" {
    bucket         = "prod-client-name-terraform-state"
    key            = "prod/terraform.tfstate"  # Different state file for prod
    region         = "eu-west-3"
    encrypt        = true
    dynamodb_table = "terraform-state-locks-ddb"
  }
}

# Single AWS provider configuration
provider "aws" {
  region = var.region
}

# ====================================================================
# CONDITIONAL KUBERNETES PROVIDER CONFIGURATION
# ====================================================================
# These providers are configured conditionally based on EKS deployment
# Using data sources to safely handle the conditional configuration

# Data source to get EKS cluster info when it exists
data "aws_eks_cluster" "cluster" {
  count = var.deploy_eks ? 1 : 0
  name  = "${var.project_name}-eks-cluster"
  
  depends_on = [module.platform]
}

data "aws_eks_cluster_auth" "cluster" {
  count = var.deploy_eks ? 1 : 0
  name  = "${var.project_name}-eks-cluster"
  
  depends_on = [module.platform]
}

# Kubernetes provider - only active when EKS is deployed
provider "kubernetes" {
  host                   = var.deploy_eks && length(data.aws_eks_cluster.cluster) > 0 ? data.aws_eks_cluster.cluster[0].endpoint : "https://localhost"
  cluster_ca_certificate = var.deploy_eks && length(data.aws_eks_cluster.cluster) > 0 ? base64decode(data.aws_eks_cluster.cluster[0].certificate_authority[0].data) : null
  token                  = var.deploy_eks && length(data.aws_eks_cluster_auth.cluster) > 0 ? data.aws_eks_cluster_auth.cluster[0].token : null
}

# Helm provider - only active when EKS is deployed
provider "helm" {
  kubernetes {
    host                   = var.deploy_eks && length(data.aws_eks_cluster.cluster) > 0 ? data.aws_eks_cluster.cluster[0].endpoint : "https://localhost"
    cluster_ca_certificate = var.deploy_eks && length(data.aws_eks_cluster.cluster) > 0 ? base64decode(data.aws_eks_cluster.cluster[0].certificate_authority[0].data) : null
    token                  = var.deploy_eks && length(data.aws_eks_cluster_auth.cluster) > 0 ? data.aws_eks_cluster_auth.cluster[0].token : null
  }
}

# ====================================================================
# INFRASTRUCTURE LAYER
# ====================================================================

module "vpc" {
  source = "../../modules/vpc"

  project_name     = var.project_name
  vpc_cidr         = var.vpc_cidr
  region           = var.region
  eks_cluster_name = "${var.project_name}-eks-cluster"
}

# ====================================================================
# OPTIONAL SERVICES LAYER
# ====================================================================

module "ecr" {
  count  = var.deploy_ecr ? 1 : 0
  source = "../../modules/ecr"

  project_name       = var.project_name
  repository_names   = var.ecr_repository_names
  max_image_count    = var.ecr_max_image_count
  scan_on_push       = var.ecr_scan_on_push
  region             = var.region
}

module "ci_cd" {
  source = "../../modules/ci-cd"

  project_name       = var.project_name
  repository_names   = var.ecr_repository_names
  region             = var.region
  create_ci_user     = var.create_ci_user
  create_cd_user     = var.create_cd_user
  create_access_keys = var.create_access_keys
}

module "redis" {
  count  = var.deploy_redis ? 1 : 0
  source = "../../modules/redis"

  project_name       = var.project_name
  vpc_id             = module.vpc.vpc_id
  vpc_cidr           = var.vpc_cidr
  private_subnet_ids = module.vpc.private_subnet_ids
  node_type          = var.redis_node_type
  node_count         = var.redis_node_count
  auth_token         = var.redis_auth_token
  engine_version     = var.redis_engine_version

  depends_on = [module.vpc]
}

module "valkey_serverless" {
  count  = var.deploy_valkey_srvless ? 1 : 0
  source = "../../modules/valkey-serverless"

  project_name        = var.project_name
  vpc_id              = module.vpc.vpc_id
  vpc_cidr            = var.vpc_cidr
  private_subnet_ids  = module.vpc.private_subnet_ids
  max_storage_gb      = var.valkey_srvless_max_storage_gb
  max_ecpu_per_second = var.valkey_srvless_max_ecpu_per_second
  auth_token          = var.valkey_srvless_auth_token

  depends_on = [module.vpc]
}

module "aurora_postgres" {
  count  = var.deploy_aurora ? 1 : 0
  source = "../../modules/aurora-postgres"

  project_name        = var.project_name
  vpc_id              = module.vpc.vpc_id
  vpc_cidr            = var.vpc_cidr
  private_subnet_ids  = module.vpc.private_subnet_ids
  
  instance_class      = var.postgres_instance_class
  instance_count      = var.postgres_instance_count
  engine_version      = var.postgres_engine_version
  database_name       = var.postgres_database_name
  master_username     = var.postgres_master_username
  master_password     = var.postgres_master_password
  deletion_protection = var.postgres_deletion_protection
  skip_final_snapshot = var.postgres_skip_final_snapshot
  
  availability_zones = ["${var.region}a", "${var.region}b"]

  depends_on = [module.vpc]
}

module "aurora_postgres_serverless" {
  count  = var.deploy_aurora_srvless ? 1 : 0
  source = "../../modules/aurora-postgres-serverless"

  project_name        = var.project_name
  vpc_id              = module.vpc.vpc_id
  vpc_cidr            = var.vpc_cidr
  private_subnet_ids  = module.vpc.private_subnet_ids
  
  engine_version              = var.postgres_srvless_engine_version
  database_name               = var.postgres_srvless_database_name
  master_username             = var.postgres_srvless_master_username
  master_password             = var.postgres_srvless_master_password
  deletion_protection         = var.postgres_srvless_deletion_protection
  skip_final_snapshot         = var.postgres_srvless_skip_final_snapshot
  
  auto_pause                  = var.postgres_srvless_auto_pause
  max_capacity                = var.postgres_srvless_max_capacity
  min_capacity                = var.postgres_srvless_min_capacity
  seconds_until_auto_pause    = var.postgres_srvless_seconds_until_auto_pause
  timeout_action              = var.postgres_srvless_timeout_action
  
  availability_zones = ["${var.region}a", "${var.region}b"]

  depends_on = [module.vpc]
}

# ====================================================================
# PLATFORM LAYER (EKS + ALB CONTROLLER)
# ====================================================================
# This single module call replaces all the complex provider configuration
# and ALB controller state tracking that was previously in this file

module "platform" {
  source = "../../modules/platform"

  # Handle conditional deployment through module variables
  deploy_eks = var.deploy_eks

  project_name       = var.project_name
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids
  region             = var.region

  # EKS Configuration
  kubernetes_version = var.kubernetes_version
  instance_type      = var.eks_instance_type
  desired_capacity   = var.eks_desired_capacity
  max_capacity       = var.eks_max_capacity
  min_capacity       = var.eks_min_capacity

  # ALB Controller Configuration
  deploy_alb_controller            = var.deploy_alb_controller
  enable_cloudflare_ip_restriction = var.enable_cloudflare_ip_restriction

  depends_on = [module.vpc]
} 