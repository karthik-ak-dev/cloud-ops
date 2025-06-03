# Microservices Helm Charts

This directory contains Helm charts for deploying microservices on Kubernetes with secure AWS access via IRSA (IAM Roles for Service Accounts).

## Directory Structure

```
helm/
├── charts/                  # Helm charts
│   └── microservice/        # Base chart for all microservices
├── values/                  # Environment-specific values
│   ├── dev/                 # Development environment values
│   └── prod/                # Production environment values
└── README.md               # This file
```

## Architecture

- **Base Chart**: We use a single reusable chart template (`microservice`) that defines all the common Kubernetes resources (Deployments, Services, HPAs, Ingresses)
- **Service-specific Values**: Each service has its own values file that overrides the defaults from the base chart
- **Environment-specific Values**: Values are organized by environment (dev, staging, prod)
- **IRSA Integration**: All services use IAM Roles for Service Accounts for secure AWS access

## AWS Integration

### IRSA (IAM Roles for Service Accounts)
All services are configured with IRSA for secure AWS access:
- **No hardcoded credentials**: Applications automatically receive temporary AWS credentials
- **Principle of least privilege**: Each service only gets the permissions it needs  
- **Audit trail**: All AWS API calls are logged with the specific pod identity

### ALB Integration
The charts are configured to work with AWS Application Load Balancer (ALB) Ingress Controller for external access. The ALB controller is automatically deployed via Terraform.

## Prerequisites

1. **EKS cluster running** (provisioned via Terraform with IRSA enabled)
2. **[Helm](https://helm.sh/docs/intro/install/) installed** (v3.x)
3. **kubectl configured** to access your EKS cluster
4. **AWS Load Balancer Controller** (automatically installed via Terraform)

## IRSA Configuration

Each service automatically gets AWS access through ServiceAccount annotations:

```yaml
serviceAccount:
  create: true
  name: my-service-sa
  annotations:
    # This provides secure AWS access without storing credentials
    eks.amazonaws.com/role-arn: "arn:aws:iam::account:role/app-full-access-role"
```

## Deploying Services

### Get Role ARN from Terraform
```bash
cd terraform/environments/dev
terraform output app_full_access_role_arn
# Copy this ARN to your values files
```

### Deploy to Environments
```bash
# Deploy cloud-ops-nodejs-ms to dev environment
helm install cloud-ops-nodejs-ms-dev ./charts/microservice \
  -f ./values/dev/cloud-ops-nodejs-ms.yaml

# Deploy to production
helm install cloud-ops-nodejs-ms-prod ./charts/microservice \
  -f ./values/prod/cloud-ops-nodejs-ms.yaml
```

## Upgrading Services

To upgrade a deployed service:

```bash
helm upgrade cloud-ops-nodejs-ms-dev ./charts/microservice \
  -f ./values/dev/cloud-ops-nodejs-ms.yaml
```

## Adding a New Service

To add a new service:

1. **Create values file** for each environment
2. **Add ServiceAccount configuration** with correct IAM role ARN
3. **Deploy** using the base chart with the new values file

### Example New Service Values
```yaml
name: my-new-service
environment: dev

# Required: ServiceAccount for AWS access
serviceAccount:
  create: true
  name: my-new-service-sa
  annotations:
    eks.amazonaws.com/role-arn: "arn:aws:iam::account:role/app-full-access-role"

image:
  repository: your-ecr-repo
  tag: "latest"

# ... other configuration
```

## Security Features

- **🔒 IRSA**: Secure AWS access without storing credentials
- **🔄 Token Rotation**: Automatic 15-minute credential rotation
- **📊 Audit Trail**: All AWS access is logged via CloudTrail
- **🎯 Least Privilege**: Services only get required permissions

## Configuration

See the `values.yaml` file in the `microservice` chart for all configurable options. 