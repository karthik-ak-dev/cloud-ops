# This module is called twice from the environment's main.tf:
# 1. First call: At the beginning to configure the AWS provider
# 2. Second call: After EKS creation to configure Kubernetes and Helm providers

# Define required provider versions to ensure consistency across environments
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }
}

# AWS provider configuration - used in both the first and second call
# In the first call, this is the primary purpose
# In the second call, this provider is already initialized but is referenced by the K8s providers
provider "aws" {
  region = var.region
}

# Kubernetes provider configuration - only effectively used in the second call
# In the first call, the EKS cluster doesn't exist yet, so these variables are empty strings
# In the second call, these variables contain actual values from the EKS cluster outputs
provider "kubernetes" {
  host                   = var.eks_cluster_endpoint
  cluster_ca_certificate = base64decode(var.eks_cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", var.eks_cluster_name]
    command     = "aws"
  }
}

# Helm provider configuration - only effectively used in the second call
# This provider uses the same authentication mechanism as the Kubernetes provider
# It's used by the alb-controller module to deploy the AWS Load Balancer Controller
provider "helm" {
  kubernetes {
    host                   = var.eks_cluster_endpoint
    cluster_ca_certificate = base64decode(var.eks_cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", var.eks_cluster_name]
      command     = "aws"
    }
  }
} 