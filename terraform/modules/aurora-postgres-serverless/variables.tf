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
  description = "List of private subnet IDs for the database"
  type        = list(string)
}

variable "availability_zones" {
  description = "List of availability zones for the Aurora Serverless cluster"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "database_name" {
  description = "Name of the initial database to create"
  type        = string
  default     = "postgres-db"
}

variable "master_username" {
  description = "Master username for the database"
  type        = string
  default     = "postgres"
}

variable "master_password" {
  description = "Master password for the database"
  type        = string
  sensitive   = true
}

variable "port" {
  description = "Port on which the database accepts connections"
  type        = number
  default     = 5432
}

variable "engine_version" {
  description = "Version of the Aurora PostgreSQL engine"
  type        = string
  default     = "16.6"  # Check AWS for supported serverless versions
}

variable "backup_retention_period" {
  description = "Days to retain backups"
  type        = number
  default     = 7
}

variable "preferred_backup_window" {
  description = "Daily time range during which backups are created"
  type        = string
  default     = "02:00-03:00"
}

variable "preferred_maintenance_window" {
  description = "Weekly time range during which system maintenance can occur"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "deletion_protection" {
  description = "If the DB instance should have deletion protection enabled"
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "Determines whether a final DB snapshot is created before the DB cluster is deleted"
  type        = bool
  default     = false
}

# Serverless-specific variables
variable "auto_pause" {
  description = "Whether to enable auto pause for the Aurora Serverless cluster"
  type        = bool
  default     = true
}

variable "max_capacity" {
  description = "Maximum Aurora capacity unit for the Aurora Serverless cluster"
  type        = number
  default     = 4  # 4 ACUs
}

variable "min_capacity" {
  description = "Minimum Aurora capacity unit for the Aurora Serverless cluster"
  type        = number
  default     = 1  # 1 ACU
}

variable "seconds_until_auto_pause" {
  description = "Seconds of no activity before the Aurora Serverless cluster is paused"
  type        = number
  default     = 300  # 5 minutes
}

variable "timeout_action" {
  description = "Action to take when a scaling event times out"
  type        = string
  default     = "RollbackCapacityChange"  # or "ForceApplyCapacityChange"
} 