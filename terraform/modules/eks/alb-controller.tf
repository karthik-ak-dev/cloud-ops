# ==================================================================================
# AWS LOAD BALANCER CONTROLLER IAM CONFIGURATION
# ==================================================================================
# This file sets up the necessary IAM permissions for the AWS Load Balancer Controller,
# which automatically manages AWS Application Load Balancers (ALBs) and Network Load 
# Balancers (NLBs) when Kubernetes services or ingresses are created in the cluster.
#
# WHAT THIS DOES:
# - Creates an IAM policy with all permissions needed by the controller
# - Creates an IAM role that can only be assumed by the controller's K8s service account
# - Uses OIDC federation for secure authentication between K8s and AWS IAM
#
# HOW IT'S USED:
# 1. The role ARN output is passed to the alb-controller module (in environments/dev/main.tf)
# 2. That module creates a K8s service account with this role annotation
# 3. The module deploys the controller via Helm, which uses these permissions
# 4. Once deployed, the controller automatically provisions ALBs/NLBs when you create:
#    - Kubernetes Services of type LoadBalancer
#    - Kubernetes Ingress resources with appropriate annotations
#
# 🔗 DEPENDENCIES:
# - Requires OIDC provider from oidc-provider.tf
# - This role trusts the centralized OIDC provider for authentication
# ==================================================================================

# IAM Policy for AWS Load Balancer Controller
# This extensive policy grants precisely the permissions needed to manage load balancers,
# target groups, listeners, and associated resources like security groups
resource "aws_iam_policy" "aws_load_balancer_controller" {
  name        = "${var.project_name}-alb-controller-policy"
  description = "Policy for AWS Load Balancer Controller"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Read-only permissions to discover AWS resources
      # The controller needs to understand the cluster's network topology
      {
        Effect = "Allow"
        Action = [
          "iam:CreateServiceLinkedRole",
          "ec2:DescribeAccountAttributes",
          "ec2:DescribeAddresses",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeInternetGateways",
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeInstances",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeTags",
          "ec2:GetCoipPoolUsage",
          "ec2:DescribeCoipPools",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeLoadBalancerAttributes",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:DescribeListenerCertificates",
          "elasticloadbalancing:DescribeSSLPolicies",
          "elasticloadbalancing:DescribeRules",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeTargetGroupAttributes",
          "elasticloadbalancing:DescribeTargetHealth",
          "elasticloadbalancing:DescribeTags"
        ]
        Resource = "*"
      },
      # Permissions for integration with other AWS services
      # Needed for features like SSL certificates, Cognito auth, and WAF
      {
        Effect = "Allow"
        Action = [
          "cognito-idp:DescribeUserPoolClient",
          "acm:ListCertificates",
          "acm:DescribeCertificate",
          "iam:ListServerCertificates",
          "iam:GetServerCertificate",
          "waf-regional:GetWebACL",
          "waf-regional:GetWebACLForResource",
          "waf-regional:AssociateWebACL",
          "waf-regional:DisassociateWebACL",
          "wafv2:GetWebACL",
          "wafv2:GetWebACLForResource",
          "wafv2:AssociateWebACL",
          "wafv2:DisassociateWebACL",
          "shield:GetSubscriptionState",
          "shield:DescribeProtection",
          "shield:CreateProtection",
          "shield:DeleteProtection"
        ]
        Resource = "*"
      },
      # Security group ingress/egress management
      {
        Effect = "Allow"
        Action = [
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress"
        ]
        Resource = "*"
      },
      # Security group creation
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateSecurityGroup"
        ]
        Resource = "*"
      },
      # Tagging security groups - used for resource tracking
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateTags"
        ]
        Resource = "arn:aws:ec2:*:*:security-group/*"
        Condition = {
          StringEquals = {
            "ec2:CreateAction" = "CreateSecurityGroup"
          }
          Null = {
            "aws:RequestTag/elbv2.k8s.aws/cluster" = "false"
          }
        }
      },
      # Additional security group tag management
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateTags",
          "ec2:DeleteTags"
        ]
        Resource = "arn:aws:ec2:*:*:security-group/*"
        Condition = {
          Null = {
            "aws:RequestTag/elbv2.k8s.aws/cluster" = "true"
            "aws:ResourceTag/elbv2.k8s.aws/cluster" = "false"
          }
        }
      },
      # Security group management with tag conditions
      # Ensures controller only modifies resources it created
      {
        Effect = "Allow"
        Action = [
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:DeleteSecurityGroup"
        ]
        Resource = "*"
        Condition = {
          Null = {
            "aws:ResourceTag/elbv2.k8s.aws/cluster" = "false"
          }
        }
      },
      # Create load balancers and target groups
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:CreateLoadBalancer",
          "elasticloadbalancing:CreateTargetGroup"
        ]
        Resource = "*"
        Condition = {
          Null = {
            "aws:RequestTag/elbv2.k8s.aws/cluster" = "false"
          }
        }
      },
      # Manage listeners and rules
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:CreateListener",
          "elasticloadbalancing:DeleteListener",
          "elasticloadbalancing:CreateRule",
          "elasticloadbalancing:DeleteRule"
        ]
        Resource = "*"
      },
      # Tagging for load balancers and target groups
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:AddTags",
          "elasticloadbalancing:RemoveTags"
        ]
        Resource = [
          "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
          "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
          "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
        ]
        Condition = {
          Null = {
            "aws:RequestTag/elbv2.k8s.aws/cluster" = "true"
            "aws:ResourceTag/elbv2.k8s.aws/cluster" = "false"
          }
        }
      },
      # Tagging for listeners and rules
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:AddTags",
          "elasticloadbalancing:RemoveTags"
        ]
        Resource = [
          "arn:aws:elasticloadbalancing:*:*:listener/net/*/*/*",
          "arn:aws:elasticloadbalancing:*:*:listener/app/*/*/*",
          "arn:aws:elasticloadbalancing:*:*:listener-rule/net/*/*/*",
          "arn:aws:elasticloadbalancing:*:*:listener-rule/app/*/*/*"
        ]
      },
      # Modify load balancer and target group configurations
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:ModifyLoadBalancerAttributes",
          "elasticloadbalancing:SetIpAddressType",
          "elasticloadbalancing:SetSecurityGroups",
          "elasticloadbalancing:SetSubnets",
          "elasticloadbalancing:DeleteLoadBalancer",
          "elasticloadbalancing:ModifyTargetGroup",
          "elasticloadbalancing:ModifyTargetGroupAttributes",
          "elasticloadbalancing:DeleteTargetGroup"
        ]
        Resource = "*"
        Condition = {
          Null = {
            "aws:ResourceTag/elbv2.k8s.aws/cluster" = "false"
          }
        }
      },
      # Register and deregister targets (EC2 instances/pods)
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:RegisterTargets",
          "elasticloadbalancing:DeregisterTargets"
        ]
        Resource = "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*"
      },
      # Additional load balancer management actions
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:SetWebAcl",
          "elasticloadbalancing:ModifyListener",
          "elasticloadbalancing:AddListenerCertificates",
          "elasticloadbalancing:RemoveListenerCertificates",
          "elasticloadbalancing:ModifyRule"
        ]
        Resource = "*"
      }
    ]
  })
}

# ==================================================================================
# IAM ROLE WITH OIDC TRUST RELATIONSHIP
# ==================================================================================
# 
# This creates an IAM role that can ONLY be assumed by the specific Kubernetes
# ServiceAccount in your EKS cluster. No other entity can assume this role.
#
# HOW THE TRUST RELATIONSHIP WORKS:
# 1. Pod starts with ServiceAccount "aws-load-balancer-controller" 
# 2. EKS automatically mounts a JWT token signed by the cluster's OIDC provider
# 3. AWS SDK in the pod exchanges this token for temporary AWS credentials
# 4. AWS STS validates the token against the centralized OIDC provider
# 5. STS checks the "sub" claim matches our condition below
# 6. If valid, STS issues temporary credentials with this role's permissions
#
# AUTHENTICATION FLOW EXAMPLE:
# JWT Token "sub" claim: "system:serviceaccount:kube-system:aws-load-balancer-controller"
# Our condition allows:   "system:serviceaccount:kube-system:aws-load-balancer-controller"  
# Result: ✅ MATCH - Role assumption allowed
#
# SECURITY: Only pods using the exact ServiceAccount can assume this role
# ==================================================================================

# IAM role for the AWS Load Balancer Controller service account
resource "aws_iam_role" "aws_load_balancer_controller" {
  name = "${var.project_name}-alb-controller-role"

  # Trust policy that establishes the OIDC trust relationship
  # This references the centralized OIDC provider from oidc-provider.tf
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          # Reference to the centralized OIDC provider
          # This establishes trust with tokens issued by our EKS cluster
          Federated = aws_iam_openid_connect_provider.eks_oidc.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        
        # CRITICAL SECURITY CONDITION:
        # Only allows role assumption by the specific ServiceAccount
        # The "sub" claim in the JWT token must exactly match this value
        Condition = {
          StringEquals = {
            # Format: {oidc-url}:sub = "system:serviceaccount:{namespace}:{serviceaccount-name}"
            # Uses the centralized OIDC provider URL from oidc-provider.tf
            "${aws_iam_openid_connect_provider.eks_oidc.url}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
          }
        }
      }
    ]
  })
}

# Attach the IAM policy to the role
# This grants the specific permissions to the role
resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller" {
  policy_arn = aws_iam_policy.aws_load_balancer_controller.arn
  role       = aws_iam_role.aws_load_balancer_controller.name
} 