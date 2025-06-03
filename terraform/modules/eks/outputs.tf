output "cluster_id" {
  description = "ID of the EKS cluster"
  value       = aws_eks_cluster.main.id
}

output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "Endpoint for the EKS cluster"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Certificate authority data for the EKS cluster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

output "node_group_id" {
  description = "ID of the EKS node group"
  value       = aws_eks_node_group.main.id
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = aws_security_group.eks_cluster.id
}

# ==================================================================================
# APPLICATION IRSA ROLE ARNs
# ==================================================================================
# These outputs provide the ARNs of application-level IRSA roles that can be
# used to annotate Kubernetes ServiceAccounts for secure AWS access

output "app_full_access_role_arn" {
  description = "ARN of the IAM role for applications needing full AWS access"
  value       = aws_iam_role.app_full_access.arn
}

# ==================================================================================
# OIDC PROVIDER OUTPUTS
# ==================================================================================
# These outputs are used by other modules to reference the OIDC provider

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider - used by all IRSA roles"
  value       = aws_iam_openid_connect_provider.eks_oidc.arn
}

output "oidc_provider_url" {
  description = "URL of the OIDC provider - used in role trust policies"
  value       = replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")
}

# ==================================================================================
# INFRASTRUCTURE ROLE OUTPUTS
# ==================================================================================

output "aws_load_balancer_controller_role_arn" {
  description = "ARN of the IAM role for AWS Load Balancer Controller"
  value       = aws_iam_role.aws_load_balancer_controller.arn
}

# ================================================================================== 