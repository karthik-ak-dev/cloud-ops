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
  version  = var.kubernetes_version  # Kubernetes version (e.g., 1.33)

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
  ]

  tags = {
    Name = "${var.project_name}-eks-node-group"
  }
}

# =====================================
# EKS ADD-ONS
# =====================================
# Metrics Server - Required for HPA (Horizontal Pod Autoscaler)
# Provides resource usage data (CPU/memory) for scaling decisions
resource "aws_eks_addon" "metrics_server" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "metrics-server"
  
  # addon_version is optional - if not specified, EKS uses the default version for your cluster
  # Uncomment and update below if you want to pin to a specific version
  # addon_version             = "v0.7.2-eksbuild.1"

  # Why OVERWRITE is recommended for metrics-server:
  # 1. Metrics-server typically doesn't need customization
  # 2. EKS version is optimized for the cluster (uses port 10251 for Fargate compatibility)
  # 3. Ensures consistent configuration across environments
  # 4. Prevents installation failures due to manual deployments
  # 5. Maintains EKS management benefits (updates, security patches)
  resolve_conflicts_on_create = "OVERWRITE"  # Replace any existing manual installations with EKS-managed version
  resolve_conflicts_on_update = "OVERWRITE"  # Revert manual changes and apply EKS-managed configuration
  
  # Ensure the cluster and node group are ready before installing add-ons
  depends_on = [
    aws_eks_cluster.main,
    aws_eks_node_group.main
  ]

  tags = {
    Name = "${var.project_name}-metrics-server"
  }
} 