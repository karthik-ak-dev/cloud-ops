# CI User outputs
output "ci_user_name" {
  description = "Name of the IAM user for CI to push to ECR"
  value       = var.create_ci_user ? aws_iam_user.ci_user[0].name : ""
}

output "ci_user_arn" {
  description = "ARN of the IAM user for CI to push to ECR"
  value       = var.create_ci_user ? aws_iam_user.ci_user[0].arn : ""
}

output "ci_access_key_id" {
  description = "Access key ID for the CI user"
  value       = var.create_ci_user && var.create_access_keys ? aws_iam_access_key.ci_user_key[0].id : ""
  sensitive   = true
}

output "ci_secret_access_key" {
  description = "Secret access key for the CI user (WARNING: sensitive value)"
  value       = var.create_ci_user && var.create_access_keys ? aws_iam_access_key.ci_user_key[0].secret : ""
  sensitive   = true
}

# CD User outputs
output "cd_user_name" {
  description = "Name of the IAM user for CD to deploy to EKS"
  value       = var.create_cd_user ? aws_iam_user.cd_user[0].name : ""
}

output "cd_user_arn" {
  description = "ARN of the IAM user for CD to deploy to EKS"
  value       = var.create_cd_user ? aws_iam_user.cd_user[0].arn : ""
}

output "cd_access_key_id" {
  description = "Access key ID for the CD user"
  value       = var.create_cd_user && var.create_access_keys ? aws_iam_access_key.cd_user_key[0].id : ""
  sensitive   = true
}

output "cd_secret_access_key" {
  description = "Secret access key for the CD user (WARNING: sensitive value)"
  value       = var.create_cd_user && var.create_access_keys ? aws_iam_access_key.cd_user_key[0].secret : ""
  sensitive   = true
} 