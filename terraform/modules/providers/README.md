# Providers Module

This module centralizes provider version requirements to ensure consistency across environments. It no longer contains actual provider configurations, as those are now defined in each environment's root module.

## Usage

```hcl
# Import provider versions in each environment
module "providers" {
  source = "../../modules/providers"
}

# Then define actual provider configurations in the root module
provider "aws" {
  region = var.region
}

# Conditional Kubernetes and Helm providers when using EKS
provider "kubernetes" {
  host = var.deploy_eks ? module.eks[0].cluster_endpoint : ""
  # ...other configuration...
  alias = "eks"
}

provider "helm" {
  kubernetes {
    # ...configuration...
  }
  alias = "eks"
}

# Pass providers explicitly to modules that need them
module "alb_controller" {
  # ...
  providers = {
    kubernetes = kubernetes.eks
    helm       = helm.eks
  }
}
```

## Why This Approach?

1. **Best Practices**: Keeps provider configurations at the root level following Terraform best practices
2. **Consistency**: Centralizes provider version requirements to ensure consistency
3. **Flexibility**: Allows using count/for_each with modules that use providers
4. **Maintainability**: Clearer dependency structure and easier debugging

## Notes

- This module only defines required_providers, not actual provider configurations
- Provider blocks should be defined in each environment's root module
- When using conditional resources (like EKS), provider configurations can use conditionals directly
- Modules that need specific providers should receive them explicitly via the providers block 