variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "max_storage_gb" {
  description = "Maximum storage in GB for Valkey Serverless"
  type        = number
  default     = 10
}

variable "max_ecpu_per_second" {
  description = "Maximum eCPU per second for Valkey Serverless"
  type        = number
  default     = 20000
}

variable "auth_token" {
  description = "Auth token for Valkey"
  type        = string
  sensitive   = true
} 