# ==================================================================================
# EKS OIDC PROVIDER CONFIGURATION  
# ==================================================================================
# 
# This file creates the OpenID Connect (OIDC) identity provider that enables
# IRSA (IAM Roles for Service Accounts) for the ENTIRE EKS cluster.
#
# ⚠️  IMPORTANT: This is the FOUNDATION for ALL IRSA functionality
# - ALB Controller uses this for AWS API access
# - Application workloads use this for AWS service access  
# - Any future IRSA roles depend on this provider
#
# 🔒 SECURITY MODEL:
# 1. EKS creates a unique OIDC issuer URL for this cluster
# 2. We register this OIDC issuer with AWS IAM (this file)
# 3. We create IAM roles that trust this OIDC provider (other files)
# 4. Kubernetes ServiceAccounts get annotated with IAM role ARNs
# 5. Pods automatically receive temporary AWS credentials (15-minute tokens)
#
# 📁 FILE ORGANIZATION:
# - oidc-provider.tf      ← This file: OIDC foundation
# - alb-controller.tf     ← ALB Controller specific role
# - application-roles.tf  ← User application roles
# ==================================================================================

# Get the AWS account ID for constructing ARNs
data "aws_caller_identity" "current" {}

# Get the TLS certificate for the OIDC provider
# This retrieves the certificate from the EKS cluster's OIDC endpoint to establish trust
data "tls_certificate" "eks_oidc" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

# ==================================================================================
# OIDC IDENTITY PROVIDER
# ==================================================================================
# This is the SINGLE source of truth for IRSA in this cluster.
# All IRSA roles (ALB Controller, applications, etc.) trust this provider.

resource "aws_iam_openid_connect_provider" "eks_oidc" {
  # Standard client ID for AWS STS (Security Token Service)
  client_id_list  = ["sts.amazonaws.com"]
  
  # Certificate thumbprint to verify the OIDC provider's identity
  # This ensures tokens are actually coming from your EKS cluster
  thumbprint_list = [data.tls_certificate.eks_oidc.certificates[0].sha1_fingerprint]
  
  # The OIDC issuer URL from your EKS cluster
  # Format: https://oidc.eks.{region}.amazonaws.com/id/{cluster-id}
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer

  tags = {
    Name = "${var.project_name}-eks-oidc"
    Purpose = "IRSA-foundation-for-entire-cluster"
    Component = "security"
  }
} 