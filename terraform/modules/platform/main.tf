# ====================================================================
# PLATFORM MODULE - EKS + ALB CONTROLLER ORCHESTRATION
# ====================================================================
# This module orchestrates the complete Kubernetes platform including:
# - EKS cluster deployment (conditional)
# - ALB controller integration with proper state tracking
# - Proper dependency resolution for clean destroy operations
# ====================================================================

# Required providers for this module
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.37"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.17"
    }
  }
}

# Get current AWS account ID and region
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Create locals to store account ID and region
locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
  
  # Conditional cluster info based on deployment
  cluster_endpoint = var.deploy_eks && length(module.eks) > 0 ? module.eks[0].cluster_endpoint : null
  cluster_ca_data  = var.deploy_eks && length(module.eks) > 0 ? module.eks[0].cluster_certificate_authority_data : null
  cluster_name     = var.deploy_eks && length(module.eks) > 0 ? module.eks[0].cluster_name : null
}

# ====================================================================
# CONDITIONAL EKS CLUSTER DEPLOYMENT
# ====================================================================
module "eks" {
  count  = var.deploy_eks ? 1 : 0
  source = "../eks"

  project_name       = var.project_name
  vpc_id             = var.vpc_id
  public_subnet_ids  = var.public_subnet_ids
  private_subnet_ids = var.private_subnet_ids
  kubernetes_version = var.kubernetes_version
  instance_type      = var.instance_type
  desired_capacity   = var.desired_capacity
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
}

# ====================================================================
# CONDITIONAL ALB CONTROLLER DEPLOYMENT
# ====================================================================
# Note: Provider configuration is now handled at the root level
# This eliminates initialization issues and follows Terraform best practices
module "alb_controller" {
  count  = var.deploy_eks && var.deploy_alb_controller ? 1 : 0
  source = "../alb-controller"

  iam_role_arn  = length(module.eks) > 0 ? module.eks[0].aws_load_balancer_controller_role_arn : null
  cluster_name  = local.cluster_name
  region        = var.region
  vpc_id        = var.vpc_id

  enable_cloudflare_ip_restriction = var.enable_cloudflare_ip_restriction

  depends_on = [module.eks]
} 