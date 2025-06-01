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
