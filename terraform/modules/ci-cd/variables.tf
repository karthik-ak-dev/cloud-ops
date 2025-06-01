variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "repository_names" {
  description = "List of ECR repository names to access"
  type        = list(string)
  default     = ["services"]
}

# CI User Variables
variable "create_ci_user" {
  description = "Whether to create IAM user for CI to push to ECR"
  type        = bool
  default     = true
}

# CD User Variables
variable "create_cd_user" {
  description = "Whether to create IAM user for CD to deploy to EKS"
  type        = bool
  default     = true
}

variable "create_access_keys" {
  description = "Whether to create access keys for the users (warning: keys will be stored in state)"
  type        = bool
  default     = true
} 