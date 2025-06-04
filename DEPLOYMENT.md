# Comprehensive Deployment Guide

This guide provides complete instructions for deploying cloud infrastructure and microservices using Terraform, Kubernetes, Helm, and GitHub Actions. Following these steps will set up a production-ready infrastructure with automated CI/CD pipelines.

## Table of Contents
- [Prerequisites](#prerequisites)
- [AWS Setup](#aws-setup)
- [Infrastructure Deployment](#infrastructure-deployment)
  - [Development Environment](#development-environment)
  - [Production Environment](#production-environment)
- [Microservice Deployment](#microservice-deployment)
  - [Manual Deployment with Helm](#manual-deployment-with-helm)
  - [Automated Deployment with CI/CD](#automated-deployment-with-cicd)
- [CI/CD Pipeline Setup](#cicd-pipeline-setup)
  - [Service Repository Configuration](#service-repository-configuration)
  - [Infrastructure Repository Configuration](#infrastructure-repository-configuration)
- [Operations Guide](#operations-guide)
  - [Adding New Services](#adding-new-services)
  - [Infrastructure Updates](#infrastructure-updates)
  - [Scaling](#scaling)
  - [Monitoring](#monitoring)
- [Troubleshooting](#troubleshooting)

## Prerequisites

Ensure you have the following tools installed on your local machine:

- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) (latest version)
- [Terraform](https://developer.hashicorp.com/terraform/downloads) (v1.0.0 or newer)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) (compatible with your EKS version)
- [Helm](https://helm.sh/docs/intro/install/) (v3.x)
- [Git](https://git-scm.com/downloads) (for repository operations)

## AWS Setup

1. **Configure AWS credentials**:

   ```bash
   aws configure
   ```

   Enter your AWS Access Key ID, Secret Access Key, default region (e.g., us-east-1), and output format (json).

2. **Create S3 backend for Terraform state** (one-time setup):

   ```bash
   # Replace CLIENT_NAME with your specific client identifier
   aws s3 mb s3://${CLIENT_NAME}-terraform-state --region us-east-1
   ```

3. **Create DynamoDB table for state locking** (one-time setup):

   ```bash
   # Create the DynamoDB table for state locking
   aws dynamodb create-table \
       --table-name terraform-state-locks-ddb \
       --attribute-definitions AttributeName=LockID,AttributeType=S \
       --key-schema AttributeName=LockID,KeyType=HASH \
       --billing-mode PAY_PER_REQUEST \
       --region us-east-1
   ```

## Infrastructure Deployment

### Development Environment

1. **Clone the infrastructure repository**:

   ```bash
   git clone https://github.com/yourusername/infrastructure-repo.git
   cd infrastructure-repo
   ```

2. **Update the S3 backend configuration**:

   Edit `terraform/environments/dev/main.tf` and update the backend configuration:

   ```hcl
   terraform {
     backend "s3" {
       bucket         = "${CLIENT_NAME}-terraform-state"
       key            = "dev/terraform.tfstate"
       region         = "us-east-1"
       encrypt        = true
       dynamodb_table = "terraform-state-locks-ddb"
     }
   }
   ```

3. **Navigate to the dev environment directory**:

   ```bash
   cd terraform/environments/dev
   ```

4. **Create and customize your terraform.tfvars file**:

   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

   Edit `terraform.tfvars` with your preferred text editor:
   
   ```hcl
   # Client-specific configuration
   project_name = "CLIENT_NAME"  # Replace with your client name
   region       = "us-east-1"
   vpc_cidr     = "10.0.0.0/16"
   
   # Feature flags
   deploy_aurora = true  # Set to false to skip Aurora PostgreSQL
   deploy_redis = true   # Set to false to skip Redis ElastiCache
   deploy_ecr = true     # Set to false to skip ECR repositories
   
   # Redis Configuration
   redis_node_type  = "cache.t3.small"  # Development size
   redis_node_count = 2
   redis_auth_token = "your-strong-redis-password"  # CHANGE THIS
   
   # Aurora PostgreSQL Configuration
   postgres_instance_class = "db.t3.medium"  # Development size
   postgres_instance_count = 2
   postgres_database_name  = "postgresdb"
   postgres_master_username = "postgres"
   postgres_master_password = "your-strong-db-password"  # CHANGE THIS
   
   # EKS Configuration
   kubernetes_version   = "1.33"
   eks_instance_type    = "t3.medium"  # Development size
   eks_desired_capacity = 2
   eks_max_capacity     = 4
   eks_min_capacity     = 1
   ```

5. **Initialize Terraform**:

   ```bash
   terraform init
   ```

6. **Create a deployment plan**:

   ```bash
   terraform plan -out=tfplan
   ```

7. **Apply the infrastructure deployment**:

   ```bash
   terraform apply tfplan
   ```

   This process will take approximately 15-20 minutes to complete.

8. **Configure kubectl to communicate with your EKS cluster**:

   ```bash
   # Use the command from terraform output
   terraform output -raw eks_config_command | bash
   ```

9. **Verify EKS connection**:

   ```bash
   kubectl get nodes
   ```

### Production Environment

1. **Navigate to the prod environment directory**:

   ```bash
   cd ../prod  # From the dev directory
   ```

2. **Create and customize your terraform.tfvars file**:

   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

   Edit `terraform.tfvars`, adjusting for production:
   
   ```hcl
   # Client-specific configuration
   project_name = "CLIENT_NAME"  # Replace with your client name
   region       = "us-east-1"
   vpc_cidr     = "10.0.0.0/16"
   
   # Feature flags
   deploy_aurora = true
   deploy_redis = true
   deploy_ecr = true
   
   # Redis Configuration
   redis_node_type  = "cache.m5.large"  # Production-grade instance
   redis_node_count = 3  # More nodes for production
   redis_auth_token = "your-strong-redis-password"  # CHANGE THIS
   
   # Aurora PostgreSQL Configuration
   postgres_instance_class = "db.r5.large"  # Production-grade instance
   postgres_instance_count = 3  # More instances for production
   postgres_database_name  = "postgresdb"
   postgres_master_username = "postgres"
   postgres_master_password = "your-strong-db-password"  # CHANGE THIS
   
   # EKS Configuration
   kubernetes_version   = "1.33"
   eks_instance_type    = "m5.large"  # Production-grade instance
   eks_desired_capacity = 3
   eks_max_capacity     = 6
   eks_min_capacity     = 2
   ```

3. **Initialize, plan, and apply**:

   ```bash
   terraform init
   terraform plan -out=tfplan
   terraform apply tfplan
   ```

4. **Configure kubectl for the production cluster**:

   ```bash
   terraform output -raw eks_config_command | bash
   ```

### Key Differences Between Dev and Prod

| Resource | Development | Production |
|----------|-------------|------------|
| Instance Types | Smaller (t3.medium, etc.) | Larger (m5.large, r5.large, etc.) |
| Node Counts | Fewer (2) | More (3+) |
| Scaling | Lower capacity | Higher capacity |
| Backup Policy | Minimal | Comprehensive |

## High Availability Architecture

The infrastructure is designed for high availability across multiple AWS Availability Zones:

1. **VPC Network**:
   - Public and private subnets spread across multiple AZs
   - Internet Gateway for public internet access
   - NAT Gateway for private subnet internet access

2. **Database Layer**:
   - Aurora PostgreSQL with instances in different AZs
   - Automatic failover capabilities

3. **Cache Layer**:
   - Redis ElastiCache with multi-AZ replication
   - Automatic failover when using multiple nodes

4. **Compute Layer**:
   - EKS worker nodes distributed across multiple AZs
   - Auto-scaling capabilities for handling load changes

This multi-AZ approach ensures that your application remains available even if an entire AWS Availability Zone experiences an outage.

## Microservice Deployment

### Manual Deployment with Helm

1. **Navigate to the Helm directory**:

   ```bash
   cd ../../helm
   ```

2. **Deploy services to the desired environment**:

   ```bash
   # Development
   helm install service1-dev ./charts/microservice -f ./values/dev/service1.yaml
   
   # Production
   helm install service1-prod ./charts/microservice -f ./values/prod/service1.yaml
   ```

3. **Verify deployments**:

   ```bash
   # Check deployments
   kubectl get deployments
   
   # Check pods
   kubectl get pods
   
   # Check services
   kubectl get svc
   
   # Check ingress resources
   kubectl get ingress
   ```

4. **Get the ALB endpoint**:

   ```bash
   kubectl get ingress service1-dev -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
   ```

### Automated Deployment with CI/CD

Services are automatically deployed when:
- Code is pushed to the service repositories
- The service repository CI pipeline builds and publishes Docker images
- The infrastructure repository workflow deploys the updated services

## CI/CD Pipeline Setup

This project uses a multi-repository approach for CI/CD:
- **Service repositories**: Contain application code and build Docker images
- **Infrastructure repository**: Contains Terraform, Helm charts, and handles deployments

### Service Repository Configuration

1. **Clone your service repository**:

   ```bash
   git clone https://github.com/yourusername/service-repo.git
   cd service-repo
   ```

2. **Create GitHub Actions workflow directory**:

   ```bash
   mkdir -p .github/workflows
   ```

3. **Create the CI workflow file**:

   Copy the example CI workflow from the infrastructure repository:
   
   ```bash
   cp /path/to/infrastructure-repo/.github/ci-example-for-service-repo.yml .github/workflows/ci.yml
   ```

4. **Customize the workflow file**:

   Edit `.github/workflows/ci.yml` to update:
   - `SERVICE_NAME`: The name of your service
   - `PROJECT_NAME`: The project name that prefixes your ECR repository
   - `INFRA_REPO`: The GitHub repo path to the infrastructure repository

5. **Update the Docker image tagging** in the workflow:

   ```yaml
   # Build, tag, and push image to Amazon ECR
   - name: Build, tag, and push image to Amazon ECR
     env:
       ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
       ECR_REPOSITORY: ${{ env.PROJECT_NAME }}-services  # Single repository for all services
       SERVICE_TAG: ${{ env.SERVICE_NAME }}-${{ steps.vars.outputs.image_tag }}
       LATEST_TAG: ${{ env.SERVICE_NAME }}-latest
     run: |
       # Build Docker image
       docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$SERVICE_TAG -t $ECR_REGISTRY/$ECR_REPOSITORY:$LATEST_TAG .
       
       # Push Docker image to ECR
       docker push $ECR_REGISTRY/$ECR_REPOSITORY:$SERVICE_TAG
       docker push $ECR_REGISTRY/$ECR_REPOSITORY:$LATEST_TAG
   ```

6. **Add GitHub secrets**:

   In your service repository GitHub settings, add these secrets:
   - `AWS_ACCESS_KEY_ID`: AWS access key with ECR permissions
   - `AWS_SECRET_ACCESS_KEY`: Corresponding AWS secret key
   - `INFRA_REPO_TOKEN`: GitHub personal access token with workflow permissions on the infrastructure repo

### Infrastructure Repository Configuration

1. **Ensure Helm values files exist for each service**:

   Create environment-specific values files:
   
   ```bash
   mkdir -p helm/values/dev helm/values/prod
   touch helm/values/dev/service1.yaml helm/values/prod/service1.yaml
   ```

2. **Configure service values**:

   Edit `helm/values/dev/service1.yaml` with your service configuration:
   
   ```yaml
   # Basic service information
   name: service1
   
   # Container configuration
   image:
     repository: {AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/client-name-services
     tag: service1-latest  # Using service-name prefix in tag
     pullPolicy: Always
   
   # Service configuration
   service:
     type: ClusterIP
     port: 80
     containerPort: 8080
   
   # Ingress configuration
   ingress:
     enabled: true
     annotations:
       kubernetes.io/ingress.class: alb
       alb.ingress.kubernetes.io/scheme: internet-facing
       alb.ingress.kubernetes.io/target-type: ip
     hosts:
       - host: ""
         paths:
           - path: /service1
             pathType: Prefix
   
   # Resource limits
   resources:
     limits:
       cpu: 500m
       memory: 512Mi
     requests:
       cpu: 100m
       memory: 128Mi
   
   # Horizontal Pod Autoscaler
   autoscaling:
     enabled: true
     minReplicas: 2
     maxReplicas: 5
     targetCPUUtilizationPercentage: 80
   
   # Environment variables
   env:
     - name: DB_HOST
       value: "aurora-endpoint-from-terraform-output"
     - name: REDIS_HOST
       value: "redis-endpoint-from-terraform-output"
   ```

3. **Add GitHub secrets**:

   In your infrastructure repository GitHub settings, add these secrets:
   - `AWS_ACCESS_KEY_ID`: AWS access key with EKS permissions
   - `AWS_SECRET_ACCESS_KEY`: Corresponding AWS secret key

## Operations Guide

### Adding New Services

1. **Create a new service repository** with application code and Dockerfile

2. **Configure CI/CD** in the service repository:
   - Add the CI workflow file as described above
   - Set up the required GitHub secrets

3. **Create Helm values files** in the infrastructure repository:
   ```bash
   cp helm/values/dev/service1.yaml helm/values/dev/new-service.yaml
   cp helm/values/prod/service1.yaml helm/values/prod/new-service.yaml
   ```

4. **Customize the values files** for your new service

5. **Push code to the service repository** to trigger the CI/CD pipeline

### EKS Console Access and RBAC

By default, only the IAM entity that created the EKS cluster has access to the Kubernetes API and the AWS EKS console. To grant access to additional users:

1. **Get the IAM user/role ARN** that needs access:

   ```bash
   aws sts get-caller-identity --query Arn --output text
   ```

2. **Add the user to the aws-auth ConfigMap**:

   ```bash
   kubectl edit configmap aws-auth -n kube-system
   ```

   Here's a complete working example of an aws-auth ConfigMap:

   ```yaml
   apiVersion: v1
   data:
     mapRoles: |
       - groups:
         - system:bootstrappers
         - system:nodes
         rolearn: arn:aws:iam::035475678676:role/dev-client-name-eks-node-group-role
         username: system:node:{{EC2PrivateDNSName}}
       - rolearn: arn:aws:iam::035475678676:role/AWSReservedSSO_AdministratorAccess_8610a110c7dfff47
         username: console-user
         groups:
         - system:masters
     mapUsers: |
       - userarn: arn:aws:iam::035475678676:user/dev-client-name-cd-user
         username: ci-cd-user
         groups:
         - system:masters
   kind: ConfigMap
   metadata:
     name: aws-auth
     namespace: kube-system
   ```

   > ⚠️ **IMPORTANT**: AWS SSO roles must be added to `mapRoles`, not to `mapUsers`. Using `userarn` with a role ARN in the `mapUsers` section will not work correctly.

3. **IMPORTANT: For roles with paths (like AWS SSO roles):**

   The AWS IAM Authenticator does not support paths in role ARNs. You must remove the path from the role ARN in the ConfigMap:

   ```yaml
   # INCORRECT (with path)
   mapRoles: |
     - rolearn: arn:aws:iam::035475678676:role/aws-reserved/sso.amazonaws.com/ap-south-1/AWSReservedSSO_AdministratorAccess_8610a110c7dfff47
       username: console-user
       groups:
       - system:masters

   # CORRECT (path removed)
   mapRoles: |
     - rolearn: arn:aws:iam::035475678676:role/AWSReservedSSO_AdministratorAccess_8610a110c7dfff47
       username: console-user
       groups:
       - system:masters
   ```

   This is specifically mentioned in [AWS EKS documentation](https://docs.aws.amazon.com/eks/latest/userguide/security-iam-troubleshoot.html#security-iam-troubleshoot-cannot-view-nodes-or-workloads) under the "aws-auth ConfigMap does not grant access to the cluster" section.

4. **Available Kubernetes RBAC groups**:

   | Group | Access Level |
   |-------|-------------|
   | system:masters | Full cluster admin access |
   | system:basic-user | Basic read-only access |
   | system:nodes | For worker nodes |
   | system:bootstrappers | For node bootstrapping |

5. **Using eksctl** (alternative method):

   ```bash
   # Install eksctl if you haven't already
   curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
   sudo mv /tmp/eksctl /usr/local/bin
   
   # Add an IAM user with admin access
   eksctl create iamidentitymapping \
     --cluster dev-client-name-eks-cluster \
     --region eu-west-3 \
     --arn arn:aws:iam::035475678676:user/dev-client-name-cd-user \
     --username ci-cd-user \
     --group system:masters
     
   # Add an AWS SSO role with admin access (remove path from ARN)
   eksctl create iamidentitymapping \
     --cluster dev-client-name-eks-cluster \
     --region eu-west-3 \
     --arn arn:aws:iam::035475678676:role/AWSReservedSSO_AdministratorAccess_8610a110c7dfff47 \
     --username console-user \
     --group system:masters
   ```
   
   Note: When using eksctl with roles that have paths, you must still remove the path from the ARN.

6. **Verify the mappings**:

   ```bash
   kubectl describe configmap aws-auth -n kube-system
   ```

7. **Troubleshooting console access**:

   If you still can't access EKS resources in the console after updating the aws-auth ConfigMap, check:
   
   - Your IAM principal has the AWS managed policy `AmazonEKSClusterPolicy` attached
   - You're using the same AWS Region as your cluster
   - Try logging out completely and logging back in to refresh credentials
   - The role ARN in aws-auth doesn't have any path components as mentioned above

After adding the IAM user/role to the aws-auth ConfigMap, the user should be able to:
- Access the Kubernetes API using kubectl
- View the Kubernetes resources in the AWS EKS console
- Manage the cluster according to the permissions granted by the assigned group

### Infrastructure Updates

1. **Make changes to Terraform code** as needed

2. **Apply changes to development first**:
   ```bash
   cd terraform/environments/dev
   terraform plan -out=tfplan
   terraform apply tfplan
   ```

3. **Test thoroughly in development**

4. **Apply the same changes to production**:
   ```bash
   cd ../prod
   terraform plan -out=tfplan
   terraform apply tfplan
   ```

### Scaling

#### Kubernetes Resources

Adjust the Helm values files:

```yaml
# In helm/values/dev/service1.yaml or helm/values/prod/service1.yaml
resources:
  limits:
    cpu: 1000m    # Increase CPU limit
    memory: 1Gi   # Increase memory limit
  requests:
    cpu: 200m     # Increase CPU request
    memory: 256Mi # Increase memory request

autoscaling:
  minReplicas: 3  # Increase minimum replicas
  maxReplicas: 10 # Increase maximum replicas
```

#### Infrastructure Resources

Edit `terraform.tfvars` to adjust EKS node capacity:

```hcl
eks_desired_capacity = 4  # Increase desired capacity
eks_max_capacity = 8      # Increase maximum capacity
```

### Monitoring

Access Kubernetes dashboards:

```bash
# Deploy Kubernetes dashboard
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml

# Create admin user and get token (for production, use more restricted roles)
kubectl apply -f k8s-dashboard-admin.yaml
kubectl -n kubernetes-dashboard create token admin-user
```

## Troubleshooting

### Deployment Issues

If Helm chart deployment fails:

```bash
# Check deployment status
kubectl describe deployment <service-name>

# Check pod logs
kubectl logs -l app=<service-name>

# Check events
kubectl get events --sort-by='.lastTimestamp'
```

### Database Connection Issues

For Redis connection issues:

```bash
# Get Redis endpoint from Terraform
cd terraform/environments/dev
terraform output redis_endpoint

# Test connection from a pod in the cluster
kubectl run redis-test --rm -it --image=redis -- redis-cli -h <redis-endpoint> -a <redis-password>
```

For PostgreSQL connection issues:

```bash
# Get PostgreSQL endpoint from Terraform
terraform output aurora_cluster_endpoint

# Test connection from a pod in the cluster
kubectl run pg-test --rm -it --image=postgres -- psql -h <pg-endpoint> -U postgres -d <database_name>
```

### CI/CD Pipeline Issues

If the CI/CD pipeline fails:

1. Check GitHub Actions workflow logs in both repositories
2. Verify that GitHub secrets are correctly configured
3. Ensure ECR repositories exist and are accessible
4. Check that Helm values files exist for the service

### AWS Load Balancer Issues

If the ALB is not being created:

```bash
# Check ALB controller logs
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller

# Verify ingress has correct annotations
kubectl describe ingress <service-name>
```

### Aurora PostgreSQL Deletion Issues

If you cannot delete Aurora PostgreSQL:

```bash
# Disable deletion protection before destroying
terraform apply -var="deletion_protection=false"

# Then you can destroy the infrastructure
terraform destroy
``` 