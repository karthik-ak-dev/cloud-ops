# Cloud Infrastructure on AWS

This repository contains Terraform code to set up AWS infrastructure. It includes:

- VPC with multi-AZ public and private subnets for high availability
- Redis ElastiCache cluster (optional) with multi-AZ deployment
- Aurora PostgreSQL cluster (optional) with multi-AZ deployment
- ECR (Elastic Container Registry) repositories (optional)
- Amazon EKS (Elastic Kubernetes Service) cluster with multi-AZ worker nodes
- AWS Load Balancer Controller for EKS

## Directory Structure

```
terraform/
├── modules/                # Reusable modules
│   ├── vpc/                # VPC configuration with multi-AZ subnets
│   ├── redis/              # Redis ElastiCache configuration
│   ├── aurora-postgres/    # Aurora PostgreSQL configuration
│   ├── ecr/                # ECR repositories configuration
│   ├── eks/                # EKS cluster configuration
│   ├── alb-controller/     # AWS Load Balancer Controller
│   └── providers/          # Centralized provider version requirements
├── environments/           # Environment-specific configurations
│   ├── dev/                # Development environment
│   └── prod/               # Production environment
```

## High Availability Architecture

This infrastructure is designed for high availability across multiple AWS Availability Zones:

- **VPC Subnets**: Both public and private subnets are distributed across multiple AZs
- **EKS Worker Nodes**: Deployed across multiple private subnets in different AZs
- **Aurora PostgreSQL**: Instances are spread across different AZs with automatic failover
- **Redis ElastiCache**: Multi-AZ enabled when using multiple nodes

## Provider Configuration

This infrastructure follows Terraform best practices for provider management:

- The `providers` module in `modules/providers/` centralizes provider version requirements
- Actual provider configurations are in each environment's root module (e.g., `environments/dev/main.tf`)
- Conditional configuration is used for providers that depend on optional resources (like EKS)
- Explicit provider passing is used for modules that need specific providers (like the ALB controller)

This approach:
- Follows Terraform's recommendation to keep provider configurations at the root level
- Enables using `count` and conditionals with modules that need providers
- Maintains version consistency across environments

## Creating a New Environment

To create a new environment (e.g., production):

1. Copy the dev environment directory:

```bash
cp -r terraform/environments/dev terraform/environments/prod
```

2. Update the backend configuration in `prod/main.tf`:

```hcl
terraform {
  backend "s3" {
    bucket         = "client-terraform-state"
    key            = "prod/terraform.tfstate"  # <-- Change this
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "client-terraform-locks"
  }
}
```

3. Create a `terraform.tfvars` file with production-specific values

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0.0
- [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate credentials
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) for EKS interaction
- [Helm](https://helm.sh/docs/intro/install/) for deploying the AWS Load Balancer Controller

## S3 Backend Setup

Before initializing Terraform, you need to create an S3 bucket and a DynamoDB table for remote state storage:

```bash
# Replace CLIENT_NAME with your client identifier
aws s3 mb s3://${CLIENT_NAME}-terraform-state --region us-east-1
aws dynamodb create-table \
    --table-name ${CLIENT_NAME}-terraform-locks \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region us-east-1
```

## Client-Specific Configuration

Update the `terraform.tfvars` file with your client's specific configuration:

```hcl
# Client-specific configuration
project_name = "client-name"  # This will prefix all resources
region       = "us-east-1"
vpc_cidr     = "10.0.0.0/16"

# Feature flags
deploy_aurora = true  # Set to false to skip Aurora PostgreSQL
deploy_redis = true   # Set to false to skip Redis ElastiCache
deploy_ecr = true     # Set to false to skip ECR repositories

# Redis Configuration
redis_node_type  = "cache.t3.small"  # Use cache.m5.large for production
redis_node_count = 2                 # Use 3 for production
redis_auth_token = "your-strong-redis-password"  # CHANGE THIS

# Aurora PostgreSQL Configuration
postgres_instance_class = "db.t3.medium"  # Use db.r5.large for production
postgres_instance_count = 2               # Use 3 for production
postgres_database_name  = "postgresdb"
postgres_master_username = "postgres"
postgres_master_password = "your-strong-password-here"  # CHANGE THIS

# EKS Configuration
kubernetes_version   = "1.29"
eks_instance_type    = "t3.medium"  # Use m5.large for production
eks_desired_capacity = 2            # Use 3 for production
eks_max_capacity     = 4            # Use 6 for production
eks_min_capacity     = 1            # Use 2 for production
```

## Usage

1. Navigate to the environment directory you want to deploy:

```bash
cd terraform/environments/dev  # or prod
```

2. Create a `terraform.tfvars` file with your configuration:

```bash
cp terraform.tfvars.example terraform.tfvars
```

3. Edit the `terraform.tfvars` file to adjust your configuration and provide required values.

4. Initialize Terraform:

```bash
terraform init
```

5. Plan the deployment:

```bash
terraform plan -out=tfplan
```

6. Apply the plan:

```bash
terraform apply tfplan
```

7. Configure kubectl to connect to your EKS cluster:

```bash
aws eks update-kubeconfig --region us-east-1 --name ${CLIENT_NAME}-eks-cluster
```

## ECR Repository Usage

The infrastructure creates a single "services" ECR repository by default. When building and pushing images:

1. Tag your images with the service name as a prefix:
   ```bash
   # Format: {project_name}-services:{service-name}-{tag}
   docker tag your-image:latest 123456789012.dkr.ecr.us-east-1.amazonaws.com/client-name-services:api-service-v1.0.0
   ```

2. Push to ECR:
   ```bash
   docker push 123456789012.dkr.ecr.us-east-1.amazonaws.com/client-name-services:api-service-v1.0.0
   ```

This approach allows you to use a single repository for multiple services by using descriptive image tags.

## AWS Load Balancer Controller

The AWS Load Balancer Controller is automatically deployed to your EKS cluster. It manages AWS Elastic Load Balancers for Kubernetes Ingress resources. The controller creates Application Load Balancers (ALBs) when you create Kubernetes Ingress resources with the appropriate annotations.

### Load Balancer Types

The VPC is configured to support both public and internal load balancers:

- **Public Load Balancers**: Created in public subnets, accessible from the internet
- **Internal Load Balancers**: Created in private subnets, only accessible within the VPC

### Usage with Kubernetes Services

To create a public-facing load balancer:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
spec:
  type: LoadBalancer
  ports:
  - port: 80
  selector:
    app: frontend
```

To create an internal load balancer:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: backend-service
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-internal: "true"
spec:
  type: LoadBalancer
  ports:
  - port: 80
  selector:
    app: backend
```

### Usage with Ingress Resources

You can also use Ingress resources with ALB annotations. Example:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-service-ingress
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
spec:
  rules:
    - host: api.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: my-service
                port:
                  number: 8080
```

## Cleaning Up

To destroy the infrastructure when no longer needed:

```bash
terraform destroy
```

If you have deletion protection enabled on Aurora PostgreSQL (default), you'll need to disable it first:

```bash
terraform apply -var="deletion_protection=false"
terraform destroy
```

## Notes

- The Redis ElastiCache cluster requires an authentication token for security.
- The Aurora PostgreSQL cluster is deployed with multiple instances across different availability zones for high availability.
- The EKS cluster is deployed with worker nodes in the private subnets across multiple AZs.
- The NAT Gateway enables resources in the private subnet to access the internet.
- The AWS Load Balancer Controller creates ALBs for your services based on Ingress resources.

# Provider Architecture

This repository follows Terraform best practices for provider management:

## Key Principles

1. **Provider Versions Centralization**: The `modules/providers` module centralizes provider version requirements to ensure consistency across environments.

2. **Root Module Provider Configuration**: Actual provider configurations are defined in each environment's root module (e.g., `environments/dev/main.tf`).

3. **Conditional Provider Configuration**: For providers that depend on optional resources (like EKS), we use conditional configuration.

4. **Explicit Provider Passing**: Providers are explicitly passed to modules that need them.

## Implementation Details

### 1. Provider Versions Module

The `modules/providers` module contains only provider version requirements:

```hcl
terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
    kubernetes = { source = "hashicorp/kubernetes", version = "~> 2.23" }
    helm = { source = "hashicorp/helm", version = "~> 2.11" }
  }
}
```

### 2. Root Module Provider Configuration

In each environment, we import the provider versions and configure providers:

```hcl
# Import provider versions
module "providers" {
  source = "../../modules/providers"
}

# Configure AWS provider
provider "aws" {
  region = var.region
}

# Conditional Kubernetes/Helm providers for EKS
provider "kubernetes" {
  host = var.deploy_eks ? module.eks[0].cluster_endpoint : ""
  # ... other configuration ...
  alias = "eks"
}
```

### 3. Pass Providers to Modules

For modules that need specific providers (like the ALB controller):

```hcl
module "alb_controller" {
  # ... other configuration ...
  
  providers = {
    kubernetes = kubernetes.eks
    helm = helm.eks
  }
}
```

### 4. Module Required Providers

Modules that use providers declare their requirements:

```hcl
terraform {
  required_providers {
    kubernetes = { source = "hashicorp/kubernetes" }
    helm = { source = "hashicorp/helm" }
  }
}
```

This architecture allows for optional deployment of components like EKS while following Terraform best practices for provider management. 