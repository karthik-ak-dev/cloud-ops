resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# -----------------------------------------------------------------------
# Subnet Configuration for Kubernetes Load Balancers
# -----------------------------------------------------------------------
# The special tags on these subnets control where AWS Load Balancer Controller 
# places load balancers when Kubernetes services request them:
#
# 1. PUBLIC SUBNETS with "kubernetes.io/role/elb" = "1":
#    - Used for internet-facing load balancers
#    - Example Kubernetes service:
#      apiVersion: v1
#      kind: Service
#      metadata:
#        name: frontend-service
#      spec:
#        type: LoadBalancer
#        ports:
#        - port: 80
#        selector:
#          app: frontend
#
# 2. PRIVATE SUBNETS with "kubernetes.io/role/internal-elb" = "1":
#    - Used for internal-only load balancers
#    - Example Kubernetes service:
#      apiVersion: v1
#      kind: Service
#      metadata:
#        name: backend-service
#        annotations:
#          service.beta.kubernetes.io/aws-load-balancer-internal: "true"
#      spec:
#        type: LoadBalancer
#        ports:
#        - port: 80
#        selector:
#          app: backend
# -----------------------------------------------------------------------

# Public subnets
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  map_public_ip_on_launch = true
  availability_zone       = "${var.region}${var.availability_zones[count.index]}"

  tags = {
    Name                                           = "${var.project_name}-public-subnet-${var.availability_zones[count.index]}"
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
    "kubernetes.io/role/elb"                       = "1"
  }
}

# Private subnets
resource "aws_subnet" "private" {
  count                   = length(var.private_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet_cidrs[count.index]
  map_public_ip_on_launch = false
  availability_zone       = "${var.region}${var.availability_zones[count.index]}"

  tags = {
    Name                                           = "${var.project_name}-private-subnet-${var.availability_zones[count.index]}"
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"              = "1"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-nat-eip"
  }

  # ===================================================================
  # DEPENDENCY FIX FOR ALB CONTROLLER DESTROY ISSUES
  # ===================================================================
  # Problem: During `terraform destroy`, AWS fails with:
  #   "VPC has mapped public addresses and cannot be deleted"
  # 
  # Root Cause: EIP can be detached before Internet Gateway is detached,
  # but AWS Load Balancer Controller creates ENIs that reference the IGW.
  # This creates a race condition where:
  #   1. EIP gets released
  #   2. ALB controller ENIs still attached to IGW
  #   3. IGW cannot be detached from VPC
  #   4. VPC deletion fails
  # 
  # Solution: Force EIP to wait for IGW dependency resolution
  # This ensures ALB resources are cleaned up before EIP is released
  # ===================================================================
  depends_on = [aws_internet_gateway.igw]
}

# NAT Gateway
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "${var.project_name}-nat"
  }

  depends_on = [aws_internet_gateway.igw]
}

# Route table for public subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# Route table for private subnets
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "${var.project_name}-private-rt"
  }
}

# Route table association for public subnets
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Route table association for private subnets
resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
} 