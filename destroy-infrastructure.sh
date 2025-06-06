#!/bin/bash

# ==============================================================================
# SIMPLE INFRASTRUCTURE DESTRUCTION SCRIPT
# ==============================================================================
#
# WHAT IT DOES:
# 1. Deletes Kubernetes Ingresses (removes ALBs) 
# 2. Deletes LoadBalancer Services (removes NLBs)
# 3. Runs terraform destroy
#
# WHY THIS WORKS:
# Prevents ALB dependency violations by cleaning up Kubernetes resources that
# create AWS Load Balancers BEFORE Terraform tries to destroy VPC components.
#
# PREREQUISITES:
# - AWS CLI configured with credentials
# - kubectl installed  
# - terraform installed
# - Proper AWS permissions (EKS, EC2, ELB, RDS, IAM)
#
# USAGE:
#   ./destroy-infrastructure.sh [ENVIRONMENT] [REGION] [CLIENT_NAME]
#
# EXAMPLE:
#   ./destroy-infrastructure.sh dev us-east-1 mycompany
#
# TROUBLESHOOTING:
# If destroy fails:
# 1. Wait 5 minutes for AWS eventual consistency
# 2. Check AWS Console for remaining k8s-* Load Balancers
# 3. Manually delete them and retry
#
# ==============================================================================

# chmod +x destroy-infrastructure.sh
# ./destroy-infrastructure.sh dev eu-west-3 dev-client-name

set -e

# Show help if requested
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo "Infrastructure Destruction Script"
    echo ""
    echo "USAGE:"
    echo "  ./destroy-infrastructure.sh [ENVIRONMENT] [REGION] [CLIENT_NAME]"
    echo ""
    echo "EXAMPLE:"
    echo "  ./destroy-infrastructure.sh dev us-east-1 mycompany"
    echo ""
    exit 0
fi

# Configuration
ENVIRONMENT="${1:-dev}"
REGION="${2:-us-east-1}"
CLIENT_NAME="${3:-dev-client-name}"
CLUSTER_NAME="${CLIENT_NAME}-eks-cluster"

echo "🚀 Infrastructure Destruction: $ENVIRONMENT"
echo "============================================"
echo "Region: $REGION"
echo "Client: $CLIENT_NAME"
echo "Cluster: $CLUSTER_NAME"
echo ""

# Confirmation
echo "⚠️  This will destroy ALL infrastructure in the $ENVIRONMENT environment!"
read -p "Type 'destroy' to confirm: " confirmation
if [ "$confirmation" != "destroy" ]; then
    echo "❌ Cancelled"
    exit 1
fi

# ==============================================================================
# STEP 1: CLEANUP KUBERNETES RESOURCES THAT CREATE AWS LOAD BALANCERS
# ==============================================================================

echo ""
echo "🧹 Step 1: Removing Kubernetes resources that create AWS Load Balancers..."

# Try to connect to cluster
if aws eks update-kubeconfig --region "$REGION" --name "$CLUSTER_NAME" 2>/dev/null; then
    echo "✅ Connected to EKS cluster"
    
    # Delete all Ingresses (these create ALBs)
    echo "  🌐 Deleting Ingresses..."
    kubectl delete ingress --all --all-namespaces --ignore-not-found=true
    
    # Delete all LoadBalancer services (these create NLBs)  
    echo "  ⚖️  Deleting LoadBalancer services..."
    kubectl delete services --all-namespaces --field-selector spec.type=LoadBalancer --ignore-not-found=true
    
    echo "  ⏳ Waiting 90 seconds for AWS Load Balancer cleanup..."
    sleep 90
    echo "✅ Kubernetes cleanup completed"
else
    echo "⚠️  Cannot access EKS cluster - may already be destroyed"
    echo "   Proceeding with Terraform destroy..."
fi

# ==============================================================================
# STEP 2: FORCE CLEANUP ANY REMAINING LOAD BALANCERS  
# ==============================================================================

echo ""
echo "🔍 Step 2: Checking for remaining ALB controller Load Balancers..."

remaining_lbs=$(aws elbv2 describe-load-balancers --region "$REGION" \
    --query "LoadBalancers[?contains(LoadBalancerName, 'k8s-')] | length(@)" \
    --output text 2>/dev/null || echo "0")

if [ "$remaining_lbs" -gt "0" ]; then
    echo "  ⚠️  Found $remaining_lbs remaining Load Balancer(s) - force deleting..."
    aws elbv2 describe-load-balancers --region "$REGION" \
        --query "LoadBalancers[?contains(LoadBalancerName, 'k8s-')].[LoadBalancerArn,LoadBalancerName]" \
        --output text | while read arn name; do
            if [ ! -z "$arn" ]; then
                echo "    - Deleting: $name"
                aws elbv2 delete-load-balancer --region "$REGION" --load-balancer-arn "$arn" 2>/dev/null || true
            fi
        done
    echo "  ⏳ Waiting 60 seconds for deletion..."
    sleep 60
else
    echo "✅ No remaining Load Balancers found"
fi

# ==============================================================================
# STEP 3: TERRAFORM DESTROY
# ==============================================================================

echo ""
echo "🏗️  Step 3: Running Terraform destroy..."
echo ""

cd terraform/environments/$ENVIRONMENT

if [ ! -f "terraform.tfvars" ]; then
    echo "❌ terraform.tfvars not found in environments/$ENVIRONMENT"
    exit 1
fi

if terraform destroy -auto-approve; then
    echo ""
    echo "🎉 Infrastructure destruction completed successfully!"
    echo ""
    echo "✅ Summary:"
    echo "  ✅ Kubernetes Ingresses and LoadBalancer services deleted"
    echo "  ✅ AWS Load Balancers cleaned up"  
    echo "  ✅ Terraform infrastructure destroyed"
    echo ""
    echo "💡 Check AWS Console to verify no resources remain"
else
    echo ""
    echo "❌ Terraform destroy failed!"
    echo "   Common fixes:"
    echo "   1. Wait 5 minutes and retry: terraform destroy"
    echo "   2. Check AWS Console for remaining Load Balancers"
    echo "   3. Manually delete any k8s-* Load Balancers and retry"
    exit 1
fi 