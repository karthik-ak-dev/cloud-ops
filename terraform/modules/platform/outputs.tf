# ====================================================================
# PLATFORM MODULE OUTPUTS
# ====================================================================
# These outputs handle conditional deployment scenarios safely
# All outputs include proper null checking and validation
# ====================================================================

# EKS Cluster Outputs
output "cluster_id" {
  description = "ID of the EKS cluster"
  value       = var.deploy_eks && length(module.eks) > 0 ? module.eks[0].cluster_id : null
}

output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = var.deploy_eks && length(module.eks) > 0 ? module.eks[0].cluster_name : null
}

output "cluster_endpoint" {
  description = "Endpoint for the EKS cluster"
  value       = var.deploy_eks && length(module.eks) > 0 ? module.eks[0].cluster_endpoint : null
}

output "cluster_certificate_authority_data" {
  description = "Certificate authority data for the EKS cluster"
  value       = var.deploy_eks && length(module.eks) > 0 ? module.eks[0].cluster_certificate_authority_data : null
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = var.deploy_eks && length(module.eks) > 0 ? module.eks[0].cluster_security_group_id : null
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider"
  value       = var.deploy_eks && length(module.eks) > 0 ? module.eks[0].oidc_provider_arn : null
}

# Cluster connection info for provider configuration
output "cluster_connection_info" {
  description = "Cluster connection information for provider configuration"
  value = var.deploy_eks && length(module.eks) > 0 ? {
    endpoint           = module.eks[0].cluster_endpoint
    ca_certificate     = module.eks[0].cluster_certificate_authority_data
    cluster_name       = module.eks[0].cluster_name
  } : null
  sensitive = false
}

# ALB Controller Outputs
output "alb_controller_deployed" {
  description = "Whether ALB controller was deployed"
  value       = var.deploy_eks && var.deploy_alb_controller && length(module.alb_controller) > 0
}

output "alb_controller_helm_status" {
  description = "Status of ALB controller Helm release"
  value       = var.deploy_eks && var.deploy_alb_controller && length(module.alb_controller) > 0 ? try(module.alb_controller[0].helm_release_status, null) : null
}

output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = var.deploy_eks && var.deploy_alb_controller && length(module.alb_controller) > 0 ? try(module.alb_controller[0].alb_security_group_id, null) : null
}

# Platform Status Output
output "platform_ready" {
  description = "Indicates if the complete platform is ready for application deployment"
  value = var.deploy_eks ? (
    length(module.eks) > 0 ? (
      var.deploy_alb_controller ? (
        length(module.alb_controller) > 0 && try(module.alb_controller[0].helm_release_status, "") == "deployed"
      ) : true  # Platform ready if ALB controller not requested
    ) : false   # Platform not ready if EKS failed to deploy
  ) : true      # Platform ready if EKS not requested
}

# Deployment Summary
output "deployment_summary" {
  description = "Summary of what was deployed in this platform"
  value = {
    eks_deployed             = var.deploy_eks && length(module.eks) > 0
    alb_controller_deployed  = var.deploy_eks && var.deploy_alb_controller && length(module.alb_controller) > 0
    cluster_name            = var.deploy_eks && length(module.eks) > 0 ? module.eks[0].cluster_name : null
    platform_ready          = var.deploy_eks ? (length(module.eks) > 0 ? (var.deploy_alb_controller ? (length(module.alb_controller) > 0) : true) : false) : true
  }
} 