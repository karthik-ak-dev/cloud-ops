# ==================================================================================
# APPLICATION-LEVEL IRSA ROLE
# ==================================================================================
# This file creates an IAM role for application pods to access AWS services securely.
# This role uses IRSA (IAM Roles for Service Accounts) instead of node-level permissions.
#
# SECURITY BENEFITS:
# ✅ Pod-level permissions (not all pods get all permissions)
# ✅ Audit trail of which pod accessed which resource
# ✅ Principle of least privilege
# ✅ No long-lived credentials stored in cluster
#
# USAGE PATTERN:
# 1. Create a ServiceAccount annotated with the role ARN
# 2. Use that ServiceAccount in your pod deployment
# 3. Application automatically gets AWS credentials
#
# 🔗 DEPENDENCIES:
# - Requires OIDC provider from oidc-provider.tf
# - This role trusts the centralized OIDC provider for authentication
# ==================================================================================

# ==================================================================================
# FULL-ACCESS APPLICATION ROLE
# ==================================================================================
# For applications that need comprehensive AWS access
# This role provides access to RDS, S3, Secrets Manager, and Redis/ElastiCache

resource "aws_iam_role" "app_full_access" {
  name = "${var.project_name}-app-full-access-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        # Reference to the centralized OIDC provider
        Federated = aws_iam_openid_connect_provider.eks_oidc.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          # Uses the centralized OIDC provider URL
          "${aws_iam_openid_connect_provider.eks_oidc.url}:sub" = "system:serviceaccount:default:app-full-access-sa"
        }
      }
    }]
  })
}

# Comprehensive policies for full-access applications
resource "aws_iam_role_policy_attachment" "app_full_access_rds" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
  role       = aws_iam_role.app_full_access.name
}

resource "aws_iam_role_policy_attachment" "app_full_access_s3" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  role       = aws_iam_role.app_full_access.name
}

resource "aws_iam_role_policy_attachment" "app_full_access_secrets" {
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
  role       = aws_iam_role.app_full_access.name
}

# Redis/ElastiCache and MemoryDB access
resource "aws_iam_policy" "app_redis_access" {
  name        = "${var.project_name}-app-redis-access"
  description = "Full access to ElastiCache and MemoryDB for applications"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "elasticache:*",
          "memorydb:*"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "app_full_access_redis" {
  policy_arn = aws_iam_policy.app_redis_access.arn
  role       = aws_iam_role.app_full_access.name
} 