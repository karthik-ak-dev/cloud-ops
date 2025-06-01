# Main entry point for CI/CD module
# This module aggregates various CI/CD related resources and configurations

# CI/CD Module - IAM Users for CI and CD operations

# Get current AWS account ID
data "aws_caller_identity" "current" {}

#############################
# CI User for ECR operations
#############################

# CI user for ECR access
resource "aws_iam_user" "ci_user" {
  count = var.create_ci_user ? 1 : 0
  
  name = "${var.project_name}-ci-user"
  
  tags = {
    Name = "${var.project_name}-ci-user"
  }
}

# ECR access policy for CI user
resource "aws_iam_user_policy" "ci_ecr_policy" {
  count = var.create_ci_user ? 1 : 0
  
  name = "ECRPushPolicy"
  user = aws_iam_user.ci_user[0].name
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]
        Resource = [
          for repo in var.repository_names : 
            "arn:aws:ecr:${var.region}:${data.aws_caller_identity.current.account_id}:repository/${var.project_name}-${repo}"
        ]
      }
    ]
  })
}

# Access keys for the CI user
resource "aws_iam_access_key" "ci_user_key" {
  count = var.create_ci_user && var.create_access_keys ? 1 : 0
  
  user = aws_iam_user.ci_user[0].name
}

#############################
# CD User for deployments
#############################

# CD user for EKS/K8s deployments
resource "aws_iam_user" "cd_user" {
  count = var.create_cd_user ? 1 : 0
  
  name = "${var.project_name}-cd-user"
  
  tags = {
    Name = "${var.project_name}-cd-user"
  }
}

# Policy for EKS access
resource "aws_iam_user_policy" "cd_eks_policy" {
  count = var.create_cd_user ? 1 : 0
  
  name = "EKSDeployPolicy"
  user = aws_iam_user.cd_user[0].name
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # EKS cluster access
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:AccessKubernetesApi"
        ]
        Resource = "*"
      },
      # ECR read-only access
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchGetImage"
        ]
        Resource = [
          for repo in var.repository_names : 
            "arn:aws:ecr:${var.region}:${data.aws_caller_identity.current.account_id}:repository/${var.project_name}-${repo}"
        ]
      },
      # ALB ingress controller permissions if using ALB Ingress
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeTargetHealth",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:DescribeRules"
        ]
        Resource = "*"
      }
    ]
  })
}

# Access keys for the CD user
resource "aws_iam_access_key" "cd_user_key" {
  count = var.create_cd_user && var.create_access_keys ? 1 : 0
  
  user = aws_iam_user.cd_user[0].name
}

#############################
# CI/CD Access Information
#############################

# UNDERSTANDING USER ACCESS RIGHTS:
# 
# 1. CI User (Continuous Integration):
#    - Purpose: Used by CI pipelines to build and push Docker images to ECR
#    - Permissions:
#      a) ECR Authentication: Can get authorization tokens to authenticate with ECR
#      b) Repository Access: Can view, push, and manage images in the specified ECR repositories
#      c) Layer Operations: Can upload, download, and manage image layers
#    - When to use: Configure in GitHub Actions or other CI tools that build and push Docker images
#
# 2. CD User (Continuous Deployment):
#    - Purpose: Used by CD pipelines to deploy applications to EKS clusters
#    - Permissions:
#      a) EKS Access: Can describe and access Kubernetes API in EKS clusters
#      b) ECR Read-Only: Can pull images from ECR but CANNOT push new images
#      c) Load Balancer Visibility: Can view ALB/ELB resources (for ALB Ingress Controller)
#    - When to use: Configure in GitHub Actions or other CD tools that deploy to Kubernetes
#
# Note on Separation of Concerns:
#    - CI and CD users have separate permissions following the principle of least privilege
#    - CI pipeline cannot deploy to Kubernetes (reduces breach impact)
#    - CD pipeline cannot push new images (maintains image integrity)
#
# RETRIEVING ACCESS KEYS:
# Note: Terraform will store these in state - consider using SSM Parameter Store or Secrets Manager instead
# 
# WHY THIS APPROACH: While OIDC is more secure for GitHub Actions, this method provides flexibility
# to work with any CI/CD platform (Jenkins, GitLab, CircleCI, etc.) without being tied to one vendor's
# authentication mechanism.
#
# Run these commands to retrieve the access keys (replace 'ci_cd' with your module name if different):
#
# For CI user credentials:
#   echo "nonsensitive(module.ci_cd.ci_access_key_id)" | terraform console
#   echo "nonsensitive(module.ci_cd.ci_secret_access_key)" | terraform console
#
# For CD user credentials:
#   echo "nonsensitive(module.ci_cd.cd_access_key_id)" | terraform console
#   echo "nonsensitive(module.ci_cd.cd_secret_access_key)" | terraform console
#
# IMPORTANT: Store these values in your CI platform's secure secrets storage 