# Providers Module

This module centralizes provider configurations for AWS, Kubernetes, and Helm to avoid duplication across environments.

## Usage

```hcl
# Before EKS is created
module "providers" {
  source = "../../modules/providers"
  region = var.region
}

# After EKS is created
module "providers" {
  source                               = "../../modules/providers"
  region                               = var.region
  eks_cluster_endpoint                 = module.eks.cluster_endpoint
  eks_cluster_certificate_authority_data = module.eks.cluster_certificate_authority_data
  eks_cluster_name                     = module.eks.cluster_name
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| region | AWS region | string | `"us-east-1"` | no |
| eks_cluster_endpoint | EKS cluster endpoint | string | `""` | no |
| eks_cluster_certificate_authority_data | EKS cluster certificate authority data | string | `""` | no |
| eks_cluster_name | EKS cluster name | string | `""` | no |

## Notes

- This module should be called twice in each environment:
  1. At the beginning with just the `region` parameter to configure the AWS provider
  2. After the EKS module with the EKS outputs to configure the Kubernetes and Helm providers
- The empty defaults for the EKS variables allow the first call to succeed, as these values are only needed for the second call 