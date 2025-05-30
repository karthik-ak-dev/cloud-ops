# AWS Load Balancer Controller Module

This module deploys the AWS Load Balancer Controller to an EKS cluster. The controller allows Kubernetes to manage AWS Elastic Load Balancers by watching for Ingress and Service resources.

## Provider Requirements

This module requires the following providers to be passed from the root module:

```hcl
terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    helm = {
      source = "hashicorp/helm"
    }
  }
}
```

## Usage

```hcl
module "alb_controller" {
  count  = var.deploy_eks && var.deploy_alb_controller ? 1 : 0
  source = "../../modules/alb-controller"

  iam_role_arn  = module.eks[0].aws_load_balancer_controller_role_arn
  cluster_name  = module.eks[0].cluster_name
  region        = var.region
  vpc_id        = module.vpc.vpc_id

  # Explicitly pass providers to the module
  providers = {
    kubernetes = kubernetes.eks
    helm       = helm.eks
  }

  depends_on = [module.eks]
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| iam_role_arn | IAM role ARN for the AWS Load Balancer Controller | string | n/a | yes |
| cluster_name | EKS cluster name | string | n/a | yes |
| region | AWS region | string | n/a | yes |
| vpc_id | VPC ID where the controller will create resources | string | n/a | yes |
| chart_version | Version of the AWS Load Balancer Controller Helm chart | string | "1.4.1" | no |

## How It Works

1. Creates a Kubernetes ServiceAccount linked to the IAM role using IRSA (IAM Roles for Service Accounts)
2. Deploys the AWS Load Balancer Controller via Helm
3. Configures the controller to manage resources in the specified cluster and VPC

## Related Resources

The IAM role for the controller is created by the EKS module and passed to this module.

## Annotations for Ingress Resources

To use the controller with Kubernetes Ingress resources, add the following annotations:

```yaml
annotations:
  kubernetes.io/ingress.class: alb
  alb.ingress.kubernetes.io/scheme: internet-facing  # or internal
  alb.ingress.kubernetes.io/target-type: ip
``` 