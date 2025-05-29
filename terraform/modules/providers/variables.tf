variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  type        = string
  default     = ""
}

variable "eks_cluster_certificate_authority_data" {
  description = "EKS cluster certificate authority data"
  type        = string
  default     = ""
}

variable "eks_cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = ""
} 