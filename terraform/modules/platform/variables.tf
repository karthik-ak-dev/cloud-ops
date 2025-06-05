variable "deploy_eks" {
  description = "Whether to deploy EKS cluster and related resources"
  type        = bool
  default     = true
}

variable "project_name" {
  description = "Name of the project for resource naming"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where platform will be deployed"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for EKS cluster"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for EKS worker nodes"
  type        = list(string)
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.33"
}

variable "instance_type" {
  description = "EC2 instance type for EKS worker nodes"
  type        = string
  default     = "t3.medium"
}

variable "desired_capacity" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "max_capacity" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 4
}

variable "min_capacity" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "deploy_alb_controller" {
  description = "Whether to deploy AWS Load Balancer Controller"
  type        = bool
  default     = true
}

variable "enable_cloudflare_ip_restriction" {
  description = "Whether to restrict ALB access to Cloudflare IP ranges only"
  type        = bool
  default     = false
} 