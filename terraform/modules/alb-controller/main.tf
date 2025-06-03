# ====================================================================
# AWS LOAD BALANCER CONTROLLER DEPLOYMENT
# ====================================================================
# This file deploys the AWS Load Balancer Controller into the EKS cluster
# using Helm. The controller watches for Kubernetes Service and Ingress
# resources and creates corresponding AWS load balancers automatically.
#
# The deployment uses IAM Roles for Service Accounts (IRSA) to securely
# provide AWS permissions to the controller without storing credentials.
#
# SSL HANDLING:
# This module only deploys the ALB controller. SSL termination should be
# handled by Cloudflare or other CDN services for better performance.
# ====================================================================

# Required providers declaration - this allows explicit provider passing from root module
# Note: Version constraints are centralized in the providers module
terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    helm = {
      source = "hashicorp/helm"
    }
    aws = {
      source = "hashicorp/aws"
    }
  }
}

# =====================================================================
# ALB SECURITY GROUP
# =====================================================================
# Security group for Application Load Balancers created by this controller
# This provides proper security boundaries for ALB traffic

resource "aws_security_group" "alb" {
  name        = "${var.cluster_name}-alb-sg"
  description = "Security group for Application Load Balancers"
  vpc_id      = var.vpc_id

  # Egress rule - allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name      = "${var.cluster_name}-alb-sg"
    Purpose   = "ALB-security-group"
    ManagedBy = "terraform-alb-controller"
  }
}

# Default HTTP access rule (when Cloudflare restriction is disabled)
resource "aws_security_group_rule" "alb_http_default" {
  count             = var.enable_cloudflare_ip_restriction ? 0 : 1
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
  description       = "HTTP from anywhere"
}

# Cloudflare-only HTTP access rule (when enabled)
resource "aws_security_group_rule" "alb_cloudflare_http" {
  count             = var.enable_cloudflare_ip_restriction ? 1 : 0
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = var.cloudflare_ipv4_ranges
  security_group_id = aws_security_group.alb.id
  description       = "HTTP from Cloudflare IP ranges only"
}

# ---------------------------------------------------------------------
# KUBERNETES SERVICE ACCOUNT WITH IAM ROLE
# ---------------------------------------------------------------------
# Create a Kubernetes service account that's linked to the IAM role
# This enables pods using this service account to assume the IAM role
# and make AWS API calls without storing credentials
resource "kubernetes_service_account" "aws_load_balancer_controller" {
  metadata {
    # Standard name expected by the AWS Load Balancer Controller
    name      = "aws-load-balancer-controller"
    
    # Deploy to kube-system namespace (for system-level components)
    namespace = "kube-system"
    
    # This annotation is the magic that enables IRSA (IAM Roles for Service Accounts)
    # It links this K8s service account to the IAM role we created in the EKS module
    annotations = {
      "eks.amazonaws.com/role-arn" = var.iam_role_arn
    }
    
    # Standard labels for identification and management
    labels = {
      "app.kubernetes.io/name"       = "aws-load-balancer-controller"
      "app.kubernetes.io/component"  = "controller"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

# ---------------------------------------------------------------------
# HELM CHART DEPLOYMENT
# ---------------------------------------------------------------------
# Deploy the AWS Load Balancer Controller using Helm
# This installs the controller with proper configuration to work with our cluster
resource "helm_release" "aws_load_balancer_controller" {
  # Name of the Helm release
  name       = "aws-load-balancer-controller"
  
  # Official AWS Helm chart repository
  repository = "https://aws.github.io/eks-charts"
  
  # The specific chart to install
  chart      = "aws-load-balancer-controller"
  
  # Install to the same namespace as the service account
  namespace  = "kube-system"
  
  # Version can be specified as a variable for better update control
  version    = var.chart_version

  # ---------------------------------------------------------------------
  # CHART CONFIGURATION VALUES
  # ---------------------------------------------------------------------
  
  # Tell the controller which EKS cluster to use
  # This ensures the controller only manages resources in this cluster
  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  # Disable the default service account creation
  # This is critical - we want to use our custom SA with the IAM role
  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  # Use our pre-created service account with the IAM role
  # This connects the controller pods to the IAM permissions
  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account.aws_load_balancer_controller.metadata[0].name
  }

  # Specify the AWS region where resources will be created
  # The controller needs this to make properly scoped API calls
  set {
    name  = "region"
    value = var.region
  }

  # Specify the VPC ID where the controller will create resources
  # This ensures load balancers are created in the right VPC
  set {
    name  = "vpcId"
    value = var.vpc_id
  }

  # Ensure the service account exists before deploying the chart
  # This prevents race conditions during initial deployment
  depends_on = [kubernetes_service_account.aws_load_balancer_controller]
} 