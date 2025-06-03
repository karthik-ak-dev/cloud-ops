# AWS Load Balancer Controller Module

This module deploys the AWS Load Balancer Controller to an EKS cluster using Helm and manages ALB-specific security groups. For SSL termination, we recommend using Cloudflare or other CDN services for better performance and security.

## Features

✅ **ALB Controller Deployment**: Automatically manages AWS Application Load Balancers  
✅ **IRSA Integration**: Secure AWS access without storing credentials  
✅ **Helm-based Deployment**: Industry-standard Kubernetes package management  
✅ **ALB Security Groups**: Creates and manages security groups for ALBs
✅ **Cloudflare Ready**: Optional IP restriction for Cloudflare-only access  

## Prerequisites

1. **EKS Cluster**: Running EKS cluster with IRSA enabled
2. **IAM Role**: ALB Controller IAM role created (typically by EKS module)
3. **Helm Provider**: Configured Helm provider for the cluster

## Usage

### Basic Usage
```hcl
module "alb_controller" {
  source = "../../modules/alb-controller"

  iam_role_arn = module.eks.aws_load_balancer_controller_role_arn
  cluster_name = module.eks.cluster_name
  region       = var.region
  vpc_id       = module.vpc.vpc_id
}
```

### With Cloudflare IP Restriction
```hcl
module "alb_controller" {
  source = "../../modules/alb-controller"

  iam_role_arn = module.eks.aws_load_balancer_controller_role_arn
  cluster_name = module.eks.cluster_name
  region       = var.region
  vpc_id       = module.vpc.vpc_id

  # Security: Restrict ALB to Cloudflare IPs only
  enable_cloudflare_ip_restriction = true
}
```

## Integration with Helm Values

### Cloudflare SSL Termination (Recommended)
```yaml
# helm/values/dev/service.yaml
ingress:
  enabled: true
  annotations:
    alb.ingress.kubernetes.io/group.name: dev-client-name
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}]'  # HTTP only
    # Use security group created by this module
    alb.ingress.kubernetes.io/security-groups: "sg-1234567890abcdef0"
  hosts:
    - host: api.yourdomain.com  # Your Cloudflare-managed domain
      paths:
        - path: /your-service
          pathType: Prefix
```

### Development without Domain
```yaml
# For development/testing without a custom domain
ingress:
  enabled: true
  annotations:
    alb.ingress.kubernetes.io/group.name: dev-client-name
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}]'
    alb.ingress.kubernetes.io/security-groups: "sg-1234567890abcdef0"
  hosts:
    # No host restriction - accepts ALB's AWS DNS
    - paths:
        - path: /your-service
          pathType: Prefix
```

Access via: `http://k8s-cluster-alb-xyz.region.elb.amazonaws.com/your-service`

## Variables

| Variable | Description | Type | Default | Required |
|----------|-------------|------|---------|----------|
| `iam_role_arn` | IAM role ARN for ALB Controller | `string` | - | Yes |
| `cluster_name` | EKS cluster name | `string` | - | Yes |
| `region` | AWS region | `string` | - | Yes |
| `vpc_id` | VPC ID | `string` | - | Yes |
| `chart_version` | Helm chart version | `string` | `"1.5.3"` | No |
| `enable_cloudflare_ip_restriction` | Restrict ALB to Cloudflare IPs only | `bool` | `false` | No |
| `cloudflare_ipv4_ranges` | Cloudflare IPv4 ranges | `list(string)` | (built-in) | No |

## Outputs

| Output | Description |
|--------|-------------|
| `helm_release_name` | Helm release name |
| `helm_release_status` | Helm release status |
| `alb_security_group_id` | ALB security group ID |

## Cloudflare SSL Architecture

**How it works:**
1. Users connect to `https://api.yourdomain.com` (HTTPS)
2. Cloudflare terminates SSL and proxies to ALB (HTTP)
3. ALB routes to your pods

**Benefits:**
- ✅ No certificate management
- ✅ Global CDN performance
- ✅ DDoS protection included
- ✅ Automatic SSL certificate renewal
- ✅ No Route53 dependency

## Security: Preventing Direct ALB Access

To prevent users from bypassing Cloudflare and accessing your ALB directly, configure the `enable_cloudflare_ip_restriction` variable:

### Option 1: Terraform Configuration (Recommended)

Enable Cloudflare IP restriction in your environment configuration:

```hcl
# terraform/environments/dev/terraform.tfvars
enable_cloudflare_ip_restriction = true  # Restrict ALB to Cloudflare IPs only
```

This automatically:
- ✅ Creates ALB security group in ALB controller module
- ✅ Restricts HTTP access to Cloudflare IP ranges only
- ✅ Outputs security group ID for ingress annotations

### Option 2: Host Header Validation

Use ALB listener rules to only accept requests with your domain:

```yaml
# In your Helm values
ingress:
  annotations:
    alb.ingress.kubernetes.io/conditions.my-service: |
      [{"field":"host-header","hostHeaderConfig":{"values":["api.yourdomain.com"]}}]
  hosts:
    - host: api.yourdomain.com
      paths:
        - path: /
          pathType: Prefix
```

### Option 3: Application-Level Checks

Add validation in your application:

```javascript
// Example in Node.js
app.use((req, res, next) => {
  const allowedHosts = ['api.yourdomain.com'];
  if (!allowedHosts.includes(req.headers.host)) {
    return res.status(403).json({ error: 'Direct access not allowed' });
  }
  next();
});
```

### Security Configuration

```yaml
# helm/values/dev/service.yaml
ingress:
  annotations:
    # Use security group created by ALB controller module
    alb.ingress.kubernetes.io/security-groups: "sg-1234567890abcdef0"
    alb.ingress.kubernetes.io/group.name: dev-client-name
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}]'
```

Get the security group ID from Terraform output:
```bash
terraform output alb_security_group_id
```

**⚠️ Important**: Cloudflare IP ranges are automatically kept up-to-date in the ALB controller module configuration.

## Troubleshooting

### ALB Controller Issues
```bash
# Check controller pods
kubectl get pods -n kube-system | grep aws-load-balancer

# Check controller logs
kubectl logs -n kube-system deployment/aws-load-balancer-controller
```

### Cloudflare Configuration
1. Set SSL/TLS mode to "Flexible" or "Full" in Cloudflare
2. Add CNAME record: `api` → `your-alb-dns-name.region.elb.amazonaws.com`
3. Enable "Proxy" (orange cloud) for the record

This approach provides excellent performance, security, and proper architectural separation! 🚀