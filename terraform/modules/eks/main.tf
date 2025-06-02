# =====================================
# EKS CLUSTER IAM ROLE
# =====================================
# This IAM role is assumed by the EKS service to create and manage 
# AWS resources needed for Kubernetes, including:
# - Network interfaces (ENIs)
# - Security groups
# - Load balancers
# - Auto Scaling groups
resource "aws_iam_role" "eks_cluster" {
  name = "${var.project_name}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach AWS-managed EKSClusterPolicy to the role
# This grants all permissions required to operate EKS, including:
# - Creating/managing network interfaces and security groups
# - Writing logs to CloudWatch
# - Managing EC2 Auto Scaling groups for node management
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

# =====================================
# WORKER NODE IAM ROLE & POLICIES
# =====================================
# This role is used by EC2 worker nodes to interact with AWS services
# Each worker node uses this role via an instance profile
# Allows the instances to register with the EKS cluster and run containers
resource "aws_iam_role" "eks_node_group" {
  name = "${var.project_name}-eks-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Worker node policies (all three are required for EKS nodes)

# 1. EKS Worker Node Policy - allows nodes to:
#    - Connect to the EKS cluster control plane
#    - Receive cluster information and configuration
#    - Register as part of the Kubernetes cluster
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_group.name
}

# 2. CNI Policy - allows nodes to:
#    - Create and configure network interfaces, routes, security groups 
#    - Required for pod networking via AWS VPC CNI
#    - Essential for pod-to-pod and pod-to-service communication
resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_group.name
}

# 3. ECR Read-Only Policy - allows nodes to:
#    - Pull container images from Amazon ECR
#    - Authenticate with the ECR service
#    - Required for running containers from private ECR repositories
resource "aws_iam_role_policy_attachment" "ecr_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_group.name
}

# 4. RDS access - AWS managed policy
resource "aws_iam_role_policy_attachment" "rds_access" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
  role       = aws_iam_role.eks_node_group.name
}

# 5. ElastiCache (Redis) and MemoryDB (Valkey) full access policy
resource "aws_iam_policy" "redis_access" {
  name        = "${var.project_name}-eks-redis-access"
  description = "Policy granting full access to ElastiCache and MemoryDB for EKS pods"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # ElastiCache (Redis) full access
      {
        Effect = "Allow"
        Action = [
          "elasticache:*"
        ]
        Resource = "*"
      },
      # MemoryDB (Valkey) full access
      {
        Effect = "Allow"
        Action = [
          "memorydb:*"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "redis_access" {
  policy_arn = aws_iam_policy.redis_access.arn
  role       = aws_iam_role.eks_node_group.name
}

# 6. AWS Secrets Manager access - AWS managed policy
resource "aws_iam_role_policy_attachment" "secrets_manager_access" {
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
  role       = aws_iam_role.eks_node_group.name
}

# 7. S3 access - AWS managed policy
resource "aws_iam_role_policy_attachment" "s3_access" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  role       = aws_iam_role.eks_node_group.name
}

# 8. Custom safety policy - explicitly deny destructive actions
resource "aws_iam_policy" "protective_guardrails" {
  name        = "${var.project_name}-eks-protective-guardrails"
  description = "Policy explicitly denying destructive actions on critical resources"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Action": [
        "s3:DeleteBucket*",
        "rds:DeleteDB*",
        "rds:DeleteGlobalCluster",
        "rds:DeleteDBCluster",
        "elasticache:DeleteCache*",
        "elasticache:DeleteReplicationGroup",
        "memorydb:DeleteCluster",
        "secretsmanager:Create*",
        "secretsmanager:Put*",
        "secretsmanager:Update*",
        "secretsmanager:Delete*",
        "secretsmanager:Restore*",
        "secretsmanager:Rotate*"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "protective_guardrails" {
  policy_arn = aws_iam_policy.protective_guardrails.arn
  role       = aws_iam_role.eks_node_group.name
}

# =====================================
# EKS CLUSTER
# =====================================
# Creates the EKS control plane which runs the Kubernetes control components:
# - API Server, Scheduler, Controller Manager, etcd
# Distributed across multiple AZs using both public and private subnets
# For high availability and fault tolerance
resource "aws_eks_cluster" "main" {
  name     = "${var.project_name}-eks-cluster"
  role_arn = aws_iam_role.eks_cluster.arn
  version  = var.kubernetes_version  # Kubernetes version (e.g., 1.29)

  vpc_config {
    # Includes both public and private subnets across multiple AZs
    subnet_ids              = concat(var.public_subnet_ids, var.private_subnet_ids)
    
    # When true, allows VPC-connected resources to access Kubernetes API
    endpoint_private_access = true
    
    # When true, allows internet-based access to Kubernetes API (secured by AWS)
    endpoint_public_access  = true
    
    # Security group controlling traffic to/from the cluster control plane
    security_group_ids      = [aws_security_group.eks_cluster.id]
  }

  # Ensure the role has necessary permissions before creating cluster
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]

  tags = {
    Name = "${var.project_name}-eks-cluster"
  }
}

# =====================================
# CLUSTER SECURITY GROUP
# =====================================
# Controls network traffic to and from the EKS cluster control plane
# By default, only allows outbound traffic from the control plane
# AWS automatically adds required inbound rules for:
# - Worker node communication
# - Kubernetes API access
resource "aws_security_group" "eks_cluster" {
  name        = "${var.project_name}-eks-cluster-sg"
  description = "Security group for EKS cluster"
  vpc_id      = var.vpc_id

  # Allow all outbound traffic from the control plane
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-eks-cluster-sg"
  }
}

# =====================================
# EKS NODE GROUP
# =====================================
# Creates and manages the EC2 instances that run your Kubernetes workloads
# - Handles auto-scaling, updates, and health checks
# - Deployed in private subnets only (security best practice)
# - Distributes across multiple AZs for high availability
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.project_name}-eks-node-group"
  node_role_arn   = aws_iam_role.eks_node_group.arn
  
  # Worker nodes in private subnets only - protected from direct internet access
  # Spread across multiple AZs for high availability
  subnet_ids      = var.private_subnet_ids
  
  # Instance type for all worker nodes (e.g., t3.medium)
  instance_types  = [var.instance_type]

  # Auto-scaling configuration for the worker nodes
  scaling_config {
    desired_size = var.desired_capacity  # Initial/target number of nodes
    max_size     = var.max_capacity      # Maximum nodes during scaling events
    min_size     = var.min_capacity      # Minimum nodes to maintain
  }

  # Ensure all required policies are attached before creating nodes
  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.ecr_read_only,
    aws_iam_role_policy_attachment.rds_access,
    aws_iam_role_policy_attachment.redis_access,
    aws_iam_role_policy_attachment.secrets_manager_access,
    aws_iam_role_policy_attachment.s3_access,
    aws_iam_role_policy_attachment.protective_guardrails,
  ]

  tags = {
    Name = "${var.project_name}-eks-node-group"
  }
} 