resource "aws_ecr_repository" "this" {
  for_each = toset(var.repository_names)

  name                 = "${var.project_name}-${each.key}"
  image_tag_mutability = var.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  tags = {
    Name = "${var.project_name}-${each.key}"
  }
}

resource "aws_ecr_lifecycle_policy" "this" {
  for_each = toset(var.repository_names)

  repository = aws_ecr_repository.this[each.key].name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep only ${var.max_image_count} images"
        selection = {
          tagStatus     = "any"
          countType     = "imageCountMoreThan"
          countNumber   = var.max_image_count
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# Optionally create a repository policy
resource "aws_ecr_repository_policy" "this" {
  for_each = var.create_repository_policy ? toset(var.repository_names) : []

  repository = aws_ecr_repository.this[each.key].name
  policy     = var.repository_policy
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# CI/CD user for ECR access
resource "aws_iam_user" "ci_ecr_user" {
  count = var.create_ci_user ? 1 : 0
  
  name = "${var.project_name}-ci-ecr-user"
  
  tags = {
    Name = "${var.project_name}-ci-ecr-user"
  }
}

# ECR access policy for CI/CD user
resource "aws_iam_user_policy" "ci_ecr_policy" {
  count = var.create_ci_user ? 1 : 0
  
  name = "ECRPushPolicy"
  user = aws_iam_user.ci_ecr_user[0].name
  
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

# Access keys for the CI/CD user
# Note: Terraform will store these in state - consider using SSM Parameter Store or Secrets Manager instead
# 
# WHY THIS APPROACH: While OIDC is more secure for GitHub Actions, this method provides flexibility
# to work with any CI/CD platform (Jenkins, GitLab, CircleCI, etc.) without being tied to one vendor's
# authentication mechanism.
#
# HOW TO VIEW THE KEYS:
# After terraform apply, run one of these commands:
#   terraform output ci_access_key_id        # View access key ID
#   terraform output ci_secret_access_key    # View secret key
#
# IMPORTANT: Store these values in your CI platform's secure secrets storage
resource "aws_iam_access_key" "ci_ecr_user_key" {
  count = var.create_ci_user && var.create_access_keys ? 1 : 0
  
  user = aws_iam_user.ci_ecr_user[0].name
} 