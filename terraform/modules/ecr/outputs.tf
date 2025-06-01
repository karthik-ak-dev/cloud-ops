output "repository_urls" {
  description = "The URLs of the ECR repositories"
  value = {
    for name in var.repository_names : 
      name => aws_ecr_repository.this[name].repository_url
  }
}

output "repository_arns" {
  description = "The ARNs of the ECR repositories"
  value = {
    for name in var.repository_names : 
      name => aws_ecr_repository.this[name].arn
  }
}

output "ci_user_name" {
  description = "Name of the IAM user for CI/CD to push to ECR"
  value       = var.create_ci_user ? aws_iam_user.ci_ecr_user[0].name : ""
}

output "ci_user_arn" {
  description = "ARN of the IAM user for CI/CD to push to ECR"
  value       = var.create_ci_user ? aws_iam_user.ci_ecr_user[0].arn : ""
}

# These are sensitive outputs that will be stored in Terraform state
output "ci_access_key_id" {
  description = "Access key ID for the CI/CD user"
  value       = var.create_ci_user && var.create_access_keys ? aws_iam_access_key.ci_ecr_user_key[0].id : ""
  sensitive   = true
}

output "ci_secret_access_key" {
  description = "Secret access key for the CI/CD user (WARNING: sensitive value)"
  value       = var.create_ci_user && var.create_access_keys ? aws_iam_access_key.ci_ecr_user_key[0].secret : ""
  sensitive   = true
} 