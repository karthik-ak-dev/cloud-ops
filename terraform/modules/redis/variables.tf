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

variable "node_type" {
  description = "ElastiCache node type"
  type        = string
  default     = "cache.t3.small"
}

variable "node_count" {
  description = "Number of Redis nodes"
  type        = number
  default     = 2
}

variable "auth_token" {
  description = "Auth token for Redis"
  type        = string
  sensitive   = true
}

variable "engine_version" {
  description = "Redis engine version"
  type        = string
  default     = "7.0"
} 