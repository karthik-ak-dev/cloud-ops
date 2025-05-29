# S3 backend configuration - Terraform state is stored here
terraform {
  backend "s3" {
    bucket         = "platform-terraform-state"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "platform-terraform-locks"
  }
}

# Phase 1: Configure AWS provider
# This first call to the providers module only effectively initializes the AWS provider
# The Kubernetes and Helm providers are also defined but aren't used yet because:
# - Their required parameters are empty strings
# - No Kubernetes resources have been created
module "providers_aws" {
  source = "../../modules/providers"
  region = var.region
}

# Phase 2: Create AWS infrastructure using the AWS provider
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

  project_name     = var.project_name
  vpc_id           = module.vpc.vpc_id
  vpc_cidr         = var.vpc_cidr
  private_subnet_id = module.vpc.private_subnet_id
  node_type        = var.redis_node_type
  node_count       = var.redis_node_count
  auth_token       = var.redis_auth_token

  depends_on = [module.vpc]
}

# Optional: Create Aurora PostgreSQL if enabled
module "aurora_postgres" {
  count  = var.deploy_aurora ? 1 : 0
  source = "../../modules/aurora-postgres"

  project_name      = var.project_name
  vpc_id            = module.vpc.vpc_id
  vpc_cidr          = var.vpc_cidr
  private_subnet_id = module.vpc.private_subnet_id
  secondary_subnet_id = module.vpc.private_subnet_id_2
  
  instance_class    = var.postgres_instance_class
  instance_count    = var.postgres_instance_count
  engine_version    = var.postgres_engine_version
  database_name     = var.postgres_database_name
  master_username   = var.postgres_master_username
  master_password   = var.postgres_master_password
  
  availability_zones = ["${var.region}b", "${var.region}c"]

  depends_on = [module.vpc]
}

# Create EKS cluster - required for Kubernetes resources
module "eks" {
  source = "../../modules/eks"

  project_name      = var.project_name
  vpc_id            = module.vpc.vpc_id
  public_subnet_id  = module.vpc.public_subnet_id
  private_subnet_id = module.vpc.private_subnet_id
  kubernetes_version = var.kubernetes_version
  instance_type     = var.eks_instance_type
  desired_capacity  = var.eks_desired_capacity
  max_capacity      = var.eks_max_capacity
  min_capacity      = var.eks_min_capacity

  depends_on = [module.vpc]
}

# Phase 3: Configure Kubernetes and Helm providers
# This second call to the providers module initializes the Kubernetes and Helm providers
# Now that the EKS cluster exists, we can use its outputs to configure the providers
module "providers_k8s" {
  source = "../../modules/providers"
  
  region                               = var.region
  eks_cluster_endpoint                 = module.eks.cluster_endpoint
  eks_cluster_certificate_authority_data = module.eks.cluster_certificate_authority_data
  eks_cluster_name                     = module.eks.cluster_name

  depends_on = [module.eks]  # This ensures EKS exists before trying to configure K8s providers
}

# Phase 4: Deploy Kubernetes resources using the Kubernetes and Helm providers
# The ALB controller is deployed using Helm
# It implicitly uses the Helm provider configured in the providers_k8s module
module "alb_controller" {
  source = "../../modules/alb-controller"

  iam_role_arn  = module.eks.aws_load_balancer_controller_role_arn
  cluster_name  = module.eks.cluster_name
  region        = var.region
  vpc_id        = module.vpc.vpc_id

  # This ensures both the EKS cluster and the K8s providers exist before deploying
  depends_on = [module.eks, module.providers_k8s]
} 