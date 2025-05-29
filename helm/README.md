# Microservices Helm Charts

This directory contains Helm charts for deploying microservices on Kubernetes.

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

## AWS ALB Integration

The charts are configured to work with AWS Application Load Balancer (ALB) Ingress Controller for external access. The ALB Ingress Controller should be installed in your EKS cluster.

## Prerequisites

1. EKS cluster running (provisioned via Terraform)
2. [Helm](https://helm.sh/docs/intro/install/) installed (v3.x)
3. kubectl configured to access your EKS cluster
4. AWS Load Balancer Controller installed in your cluster

## Installing AWS Load Balancer Controller

Before deploying services, install the AWS Load Balancer Controller:

```bash
# Add the EKS chart repo
helm repo add eks https://aws.github.io/eks-charts
helm repo update

# Install the AWS Load Balancer Controller
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=<your-cluster-name> \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller
```

## Deploying Services

To deploy a service to a specific environment:

```bash
# Deploy service1 to dev environment
helm install service1-dev ./charts/microservice -f ./values/dev/service1.yaml

# Deploy service2 to dev environment
helm install service2-dev ./charts/microservice -f ./values/dev/service2.yaml

# Deploy service1 to production
helm install service1-prod ./charts/microservice -f ./values/prod/service1.yaml
```

## Upgrading Services

To upgrade a deployed service:

```bash
helm upgrade service1-dev ./charts/microservice -f ./values/dev/service1.yaml
```

## Adding a New Service

To add a new service:

1. Create a new values file for the service in each environment folder
2. Deploy using the base chart with the new values file

## Configuration

See the `values.yaml` file in the `microservice` chart for all configurable options. 