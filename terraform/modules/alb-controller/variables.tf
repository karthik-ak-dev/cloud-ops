variable "iam_role_arn" {
  description = "ARN of the IAM role for AWS Load Balancer Controller"
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "chart_version" {
  description = "Version of the AWS Load Balancer Controller Helm chart"
  type        = string
  default     = "1.5.3"
}

variable "enable_cloudflare_ip_restriction" {
  description = "Whether to restrict ALB access to Cloudflare IP ranges only"
  type        = bool
  default     = false
}

variable "cloudflare_ipv4_ranges" {
  description = "Cloudflare IPv4 ranges (update periodically)"
  type        = list(string)
  default     = [
    "173.245.48.0/20",
    "103.21.244.0/22", 
    "103.22.200.0/22",
    "103.31.4.0/22",
    "141.101.64.0/18",
    "108.162.192.0/18",
    "190.93.240.0/20",
    "188.114.96.0/20",
    "197.234.240.0/22",
    "198.41.128.0/17",
    "162.158.0.0/15",
    "104.16.0.0/13",
    "104.24.0.0/14",
    "172.64.0.0/13",
    "131.0.72.0/22"
  ]
} 