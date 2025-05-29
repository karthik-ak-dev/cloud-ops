# Cloud Infrastructure on AWS

This repository contains Terraform code to set up AWS infrastructure. It includes:

- VPC with public and private subnets
- Redis ElastiCache cluster (optional)
- Aurora PostgreSQL cluster (optional)
- ECR (Elastic Container Registry) repositories (optional)
- Amazon EKS (Elastic Kubernetes Service) cluster
- AWS Load Balancer Controller for EKS

## Directory Structure

```
terraform/
├── modules/                # Reusable modules
│   ├── vpc/                # VPC configuration
│   ├── redis/              # Redis ElastiCache configuration
│   ├── aurora-postgres/    # Aurora PostgreSQL configuration
│   ├── ecr/                # ECR repositories configuration
│   ├── eks/                # EKS cluster configuration
│   ├── alb-controller/     # AWS Load Balancer Controller
│   └── providers/          # Centralized provider configurations
├── environments/           # Environment-specific configurations
│   └── dev/                # Development environment
```

## Provider Configuration

This infrastructure uses a centralized provider configuration approach:

- The `providers` module in `modules/providers/` contains all provider configurations
- Each environment calls this module twice:
  1. At the beginning to configure the AWS provider
  2. After the EKS module to configure Kubernetes and Helm providers
- This approach eliminates duplication and ensures consistency across environments

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

# Feature flags - Enable/disable components
deploy_aurora = true  # Set to false to skip Aurora PostgreSQL
deploy_redis = true   # Set to false to skip Redis ElastiCache
deploy_ecr = true     # Set to false to skip ECR repositories

# ECR configuration
ecr_repository_names = ["api", "frontend", "worker"]  # List of repositories to create

# Other configuration as needed...
```

## Usage

1. Navigate to the environment directory you want to deploy:

```bash
cd terraform/environments/dev
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

## AWS Load Balancer Controller

The AWS Load Balancer Controller is automatically deployed to your EKS cluster. It manages AWS Elastic Load Balancers for Kubernetes Ingress resources. The controller creates Application Load Balancers (ALBs) when you create Kubernetes Ingress resources with the appropriate annotations.

### Usage with Helm Charts

Your Kubernetes services can be exposed using Ingress resources with ALB annotations. Example:

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

## Notes

- The Redis ElastiCache cluster requires an authentication token for security.
- The Aurora PostgreSQL cluster is deployed with 2 instances across different availability zones for high availability.
- The EKS cluster is deployed with worker nodes in the private subnet.
- The NAT Gateway enables resources in the private subnet to access the internet.
- The AWS Load Balancer Controller creates ALBs for your services based on Ingress resources. 