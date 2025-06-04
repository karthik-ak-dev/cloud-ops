# EKS Module - Comprehensive Documentation

This module creates a complete Amazon EKS (Elastic Kubernetes Service) cluster with all necessary components for running production workloads securely.

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        EKS CLUSTER                             │
├─────────────────────────────────────────────────────────────────┤
│ Control Plane (Managed by AWS)                                 │
│ ├── API Server                                                 │
│ ├── etcd                                                       │
│ ├── Scheduler                                                  │
│ └── Controller Manager                                         │
├─────────────────────────────────────────────────────────────────┤
│ Worker Nodes (EC2 Instances)                                   │
│ ├── kubelet                                                    │
│ ├── kube-proxy                                                 │
│ └── AWS VPC CNI                                                │
├─────────────────────────────────────────────────────────────────┤
│ IRSA (IAM Roles for Service Accounts)                          │
│ ├── OIDC Provider                                              │
│ ├── ALB Controller Role                                        │
│ └── Application Role                                           │
└─────────────────────────────────────────────────────────────────┘
```

## 📁 Module Structure

```
terraform/modules/eks/
├── main.tf                 # EKS cluster and worker nodes
├── oidc-provider.tf        # OIDC provider for IRSA foundation
├── alb-controller.tf       # AWS Load Balancer Controller IAM setup
├── application-roles.tf    # Application-level IRSA role
├── outputs.tf              # All module outputs
├── variables.tf            # Input variables
└── README.md              # This documentation
```

---

## 🔧 Components Explained

### 1. **EKS Cluster Setup** (`main.tf`)

#### **A. Cluster IAM Role**
The EKS service needs permissions to manage AWS resources on your behalf:

```hcl
resource "aws_iam_role" "eks_cluster" {
  name = "${var.project_name}-eks-cluster-role"
  
  # Allow EKS service to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}
```

**Attached Policy**: `AmazonEKSClusterPolicy`
- Grants permissions to create/manage network interfaces, security groups
- Allows EKS to write logs to CloudWatch
- Enables management of Auto Scaling groups for nodes

#### **B. Worker Node IAM Role**
EC2 instances (worker nodes) need permissions to join the cluster and run containers:

```hcl
resource "aws_iam_role" "eks_node_group" {
  name = "${var.project_name}-eks-node-group-role"
  
  # Allow EC2 service to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}
```

**Attached Policies**:
1. **`AmazonEKSWorkerNodePolicy`**: Allows nodes to connect to EKS cluster
2. **`AmazonEKS_CNI_Policy`**: Enables pod networking via AWS VPC CNI
3. **`AmazonEC2ContainerRegistryReadOnly`**: Allows pulling container images from ECR

#### **C. EKS Cluster Resource**
The actual Kubernetes control plane:

```hcl
resource "aws_eks_cluster" "main" {
  name     = "${var.project_name}-eks-cluster"
  role_arn = aws_iam_role.eks_cluster.arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = concat(var.public_subnet_ids, var.private_subnet_ids)
    endpoint_private_access = true   # VPC resources can access API
    endpoint_public_access  = true   # Internet access to API (secured by AWS)
    security_group_ids      = [aws_security_group.eks_cluster.id]
  }
}
```

**Key Configuration**:
- **Subnets**: Uses both public and private subnets across multiple AZs for high availability
- **API Access**: Both private (from VPC) and public (from internet) access enabled
- **Security**: Protected by AWS-managed security groups and authentication

#### **D. Worker Node Group**
Managed EC2 instances that run your Kubernetes workloads:

```hcl
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.project_name}-eks-node-group"
  node_role_arn   = aws_iam_role.eks_node_group.arn
  subnet_ids      = var.private_subnet_ids  # Private subnets only
  instance_types  = [var.instance_type]

  scaling_config {
    desired_size = var.desired_capacity
    max_size     = var.max_capacity
    min_size     = var.min_capacity
  }
}
```

**Security Best Practices**:
- Nodes are placed in **private subnets only** (no direct internet access)
- Auto-scaling based on demand
- Managed updates and patching by AWS

---

### 2. **OIDC Provider Setup** (`oidc-provider.tf`)

OIDC (OpenID Connect) is the foundation that enables IRSA (IAM Roles for Service Accounts).

#### **What is IRSA?**
IRSA allows Kubernetes pods to assume AWS IAM roles securely without storing long-lived credentials. Instead of hardcoding AWS keys, pods get temporary credentials (15-minute tokens) automatically.

#### **How OIDC Works**:

1. **EKS creates a unique OIDC issuer URL** for your cluster:
   ```
   https://oidc.eks.us-west-2.amazonaws.com/id/CLUSTER-ID
   ```

2. **We register this OIDC issuer with AWS IAM**:
   ```hcl
   resource "aws_iam_openid_connect_provider" "eks_oidc" {
     client_id_list  = ["sts.amazonaws.com"]
     thumbprint_list = [data.tls_certificate.eks_oidc.certificates[0].sha1_fingerprint]
     url             = aws_eks_cluster.main.identity[0].oidc[0].issuer
   }
   ```

3. **Certificate Verification**:
   ```hcl
   data "tls_certificate" "eks_oidc" {
     url = aws_eks_cluster.main.identity[0].oidc[0].issuer
   }
   ```
   This ensures tokens are actually coming from your EKS cluster.

#### **Authentication Flow**:
```
Pod starts → EKS mounts JWT token → AWS SDK exchanges token → 
AWS STS validates → STS issues temporary credentials → Pod accesses AWS services
```

---

### 3. **AWS Load Balancer Controller** (`alb-controller.tf`)

The ALB Controller automatically creates AWS Application Load Balancers when you deploy Kubernetes Ingress resources.

#### **A. IAM Policy**
Comprehensive permissions needed to manage load balancers:

```hcl
resource "aws_iam_policy" "aws_load_balancer_controller" {
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Discover AWS resources (VPCs, subnets, etc.)
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "elasticloadbalancing:DescribeLoadBalancers",
          # ... many more discovery permissions
        ]
        Resource = "*"
      },
      # Create and manage load balancers
      {
        Effect = "Allow" 
        Action = [
          "elasticloadbalancing:CreateLoadBalancer",
          "elasticloadbalancing:CreateTargetGroup",
          # ... load balancer management permissions
        ]
        Resource = "*"
      },
      # Security group management
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateSecurityGroup",
          "ec2:AuthorizeSecurityGroupIngress",
          # ... security group permissions  
        ]
        Resource = "*"
      }
    ]
  })
}
```

#### **B. IAM Role with OIDC Trust**
This role can ONLY be assumed by the ALB controller pod:

```hcl
resource "aws_iam_role" "aws_load_balancer_controller" {
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.eks_oidc.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          # CRITICAL: Only this specific ServiceAccount can assume the role
          "${aws_iam_openid_connect_provider.eks_oidc.url}:sub" = 
            "system:serviceaccount:kube-system:aws-load-balancer-controller"
        }
      }
    }]
  })
}
```

**Security**: The condition ensures ONLY the ALB controller ServiceAccount can use this role.

---

### 4. **Application IRSA Role** (`application-roles.tf`)

This provides your applications with secure access to AWS services.

#### **Full Access Role**
For applications that need comprehensive AWS access:

```hcl
resource "aws_iam_role" "app_full_access" {
  name = "${var.project_name}-app-full-access-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.eks_oidc.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          # Only ServiceAccount named "app-full-access-sa" can assume this role
          "${aws_iam_openid_connect_provider.eks_oidc.url}:sub" = 
            "system:serviceaccount:default:app-full-access-sa"
        }
      }
    }]
  })
}
```

**Attached Policies**:
- `AmazonRDSFullAccess`: Full RDS database access
- `AmazonS3FullAccess`: Full S3 storage access  
- `SecretsManagerReadWrite`: Secrets management
- Custom policy for ElastiCache/MemoryDB (Redis) access

---

### 5. **Security Groups** (`main.tf`)

#### **Cluster Security Group**
Controls network traffic to/from the EKS control plane:

```hcl
resource "aws_security_group" "eks_cluster" {
  name_prefix = "${var.project_name}-eks-cluster-sg"
  vpc_id      = var.vpc_id

  # Allow all outbound traffic from control plane
  egress {
    from_port   = 0
    to_port     = 0  
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

**AWS Automatic Rules**: AWS automatically adds required inbound rules for:
- Worker node communication with control plane
- kubectl/API access
- Internal cluster communication

---

## 🚀 Usage Examples

### **1. Basic Application with AWS Access**

```yaml
# ServiceAccount with IRSA
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-app-sa
  namespace: default
  annotations:
    eks.amazonaws.com/role-arn: "arn:aws:iam::123456789:role/dev-client-name-app-full-access-role"
---
# Deployment using the ServiceAccount
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  template:
    spec:
      serviceAccountName: my-app-sa  # This gives AWS permissions
      containers:
      - name: app
        image: my-app:latest
        # AWS credentials automatically available!
```

### **2. Application Code (Node.js)**

```javascript
const AWS = require('aws-sdk');

// No credential configuration needed!
const s3 = new AWS.S3();
const rds = new AWS.RDS();

// Your app can now access AWS services
const buckets = await s3.listBuckets().promise();
const databases = await rds.describeDBInstances().promise();
```

### **3. ALB Controller Ingress**

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app-ingress
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
spec:
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-app-service
            port:
              number: 80
```

---

## 📊 Module Outputs

```hcl
# EKS Cluster Information
output "cluster_name"           # For kubectl configuration
output "cluster_endpoint"       # API server endpoint
output "cluster_certificate_authority_data"  # For kubectl auth

# OIDC Provider Information  
output "oidc_provider_arn"      # For other IRSA roles
output "oidc_provider_url"      # For trust policies

# IAM Role ARNs
output "aws_load_balancer_controller_role_arn"  # For ALB controller
output "app_full_access_role_arn"               # For applications
```

---

## 🔧 Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `project_name` | Project name prefix for resources | Required |
| `vpc_id` | VPC ID where EKS will be deployed | Required |
| `public_subnet_ids` | Public subnet IDs for load balancers | Required |
| `private_subnet_ids` | Private subnet IDs for worker nodes | Required |
| `kubernetes_version` | Kubernetes version | `"1.33"` |
| `instance_type` | EC2 instance type for workers | `"t3.medium"` |
| `desired_capacity` | Desired number of worker nodes | `2` |
| `max_capacity` | Maximum number of worker nodes | `4` |
| `min_capacity` | Minimum number of worker nodes | `1` |

---

## 🔒 Security Features

### **1. Network Security**
- Worker nodes in private subnets only
- Control plane accessible via both private and public endpoints
- Security groups restrict network access

### **2. IAM Security**  
- IRSA eliminates long-lived credentials
- Role-based access control per application
- Automatic credential rotation (15-minute tokens)
- Audit trail via CloudTrail

### **3. Cluster Security**
- AWS-managed control plane with automatic security updates
- Network policies can be implemented via Calico/other CNIs
- Pod security standards can be enforced

### **4. Access Control**
- RBAC (Role-Based Access Control) for Kubernetes API
- IAM roles for AWS service access
- Separate roles for different privilege levels

---

## 🛠️ Deployment Process

### **1. Apply Terraform**
```bash
cd terraform/environments/dev
terraform init
terraform plan
terraform apply
```

### **2. Configure kubectl**
```bash
aws eks update-kubeconfig --region us-west-2 --name dev-client-name-eks-cluster
```

### **3. Verify Cluster**
```bash
kubectl get nodes
kubectl get pods -n kube-system
```

### **4. Deploy Applications**
```bash
kubectl apply -f your-app-with-irsa.yaml
```

---

## 📈 Monitoring & Troubleshooting

### **Check EKS Cluster Status**
```bash
kubectl cluster-info
kubectl get nodes -o wide
```

### **Verify IRSA Setup**
```bash
# Check ServiceAccount annotation
kubectl describe serviceaccount my-app-sa

# Test AWS access from pod
kubectl exec -it <pod-name> -- aws sts get-caller-identity
```

### **ALB Controller Logs**
```bash
kubectl logs -n kube-system deployment/aws-load-balancer-controller
```

### **Common Issues**
1. **OIDC Provider Missing**: "No OpenIDConnect provider found"
   - Solution: Ensure OIDC provider is created and IAM roles reference it

2. **ALB Not Created**: Ingress exists but no load balancer
   - Check ALB controller logs
   - Verify IAM permissions and IRSA setup

3. **Application Can't Access AWS**: "Unable to locate credentials"
   - Verify ServiceAccount has correct role annotation
   - Check role trust policy conditions

---

## 🎯 Best Practices

### **1. Security**
- Use private subnets for worker nodes
- Implement principle of least privilege for IAM roles
- Regularly update Kubernetes version
- Enable audit logging

### **2. High Availability**
- Deploy across multiple Availability Zones
- Use multiple subnet types (public/private)
- Configure proper auto-scaling

### **3. Monitoring**
- Enable CloudWatch Container Insights
- Set up Prometheus/Grafana for metrics
- Configure log aggregation

### **4. Cost Optimization**
- Use Spot instances for non-critical workloads
- Implement cluster autoscaling
- Monitor resource utilization

---

This module provides a production-ready, secure, and scalable EKS cluster with modern best practices for container orchestration on AWS. 