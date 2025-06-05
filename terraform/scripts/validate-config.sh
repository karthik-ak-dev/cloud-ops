#!/bin/bash

# ====================================================================
# TERRAFORM CONFIGURATION VALIDATOR
# ====================================================================
# This script validates the Terraform configuration for production
# readiness and helps identify potential issues before deployment.
# ====================================================================

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_ROOT="$(dirname "$SCRIPT_DIR")"
ENVIRONMENTS=("dev" "prod")

# ====================================================================
# UTILITY FUNCTIONS
# ====================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# ====================================================================
# VALIDATION FUNCTIONS
# ====================================================================

validate_terraform_version() {
    log_info "Checking Terraform version..."
    
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform is not installed or not in PATH"
        return 1
    fi
    
    local version=$(terraform version -json | jq -r '.terraform_version')
    local major_version=$(echo "$version" | cut -d. -f1)
    local minor_version=$(echo "$version" | cut -d. -f2)
    
    if [[ $major_version -lt 1 ]]; then
        log_error "Terraform version $version is too old. Required: >= 1.0.0"
        return 1
    fi
    
    log_success "Terraform version $version is compatible"
}

validate_aws_credentials() {
    log_info "Checking AWS credentials..."
    
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI is not installed or not in PATH"
        return 1
    fi
    
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS credentials are not configured or invalid"
        return 1
    fi
    
    local account_id=$(aws sts get-caller-identity --query Account --output text)
    local region=$(aws configure get region || echo "us-east-1")
    
    log_success "AWS credentials valid - Account: $account_id, Region: $region"
}

validate_required_files() {
    local env=$1
    local env_dir="$TERRAFORM_ROOT/environments/$env"
    
    log_info "Validating required files for $env environment..."
    
    local required_files=(
        "main.tf"
        "variables.tf"
        "outputs.tf"
        "terraform.tfvars.example"
    )
    
    for file in "${required_files[@]}"; do
        if [[ ! -f "$env_dir/$file" ]]; then
            log_error "Missing required file: $env_dir/$file"
            return 1
        fi
    done
    
    # Check if terraform.tfvars exists (optional but recommended)
    if [[ ! -f "$env_dir/terraform.tfvars" ]]; then
        log_warning "terraform.tfvars not found in $env. Copy from terraform.tfvars.example"
    fi
    
    log_success "All required files present for $env environment"
}

validate_terraform_syntax() {
    local env=$1
    local env_dir="$TERRAFORM_ROOT/environments/$env"
    
    log_info "Validating Terraform syntax for $env environment..."
    
    cd "$env_dir"
    
    # Validate syntax
    if ! terraform fmt -check=true -diff=false . &> /dev/null; then
        log_warning "Terraform files need formatting in $env. Run 'terraform fmt'"
    fi
    
    # Validate configuration
    if ! terraform validate &> /dev/null; then
        log_error "Terraform validation failed for $env environment"
        terraform validate
        return 1
    fi
    
    log_success "Terraform syntax valid for $env environment"
    cd - > /dev/null
}

validate_module_structure() {
    log_info "Validating module structure..."
    
    local modules_dir="$TERRAFORM_ROOT/modules"
    local required_modules=(
        "vpc"
        "eks"
        "platform"
        "alb-controller"
        "ecr"
        "ci-cd"
        "redis"
        "aurora-postgres"
    )
    
    for module in "${required_modules[@]}"; do
        local module_dir="$modules_dir/$module"
        if [[ ! -d "$module_dir" ]]; then
            log_error "Missing required module: $module_dir"
            return 1
        fi
        
        # Check for required module files
        for file in "main.tf" "variables.tf" "outputs.tf"; do
            if [[ ! -f "$module_dir/$file" ]]; then
                log_error "Missing $file in module: $module_dir"
                return 1
            fi
        done
    done
    
    log_success "All required modules are present and properly structured"
}

validate_provider_versions() {
    log_info "Validating provider version consistency..."
    
    local aws_version=""
    local kubernetes_version=""
    local helm_version=""
    local inconsistency_found=false
    
    for env in "${ENVIRONMENTS[@]}"; do
        local env_dir="$TERRAFORM_ROOT/environments/$env"
        
        # Extract provider versions from main.tf
        local env_aws_version=$(grep -A 2 'aws = {' "$env_dir/main.tf" | grep 'version' | sed 's/.*"\(.*\)".*/\1/')
        local env_k8s_version=$(grep -A 2 'kubernetes = {' "$env_dir/main.tf" | grep 'version' | sed 's/.*"\(.*\)".*/\1/')
        local env_helm_version=$(grep -A 2 'helm = {' "$env_dir/main.tf" | grep 'version' | sed 's/.*"\(.*\)".*/\1/')
        
        if [[ -z "$aws_version" ]]; then
            aws_version="$env_aws_version"
            kubernetes_version="$env_k8s_version"
            helm_version="$env_helm_version"
        else
            if [[ "$aws_version" != "$env_aws_version" ]] || 
               [[ "$kubernetes_version" != "$env_k8s_version" ]] || 
               [[ "$helm_version" != "$env_helm_version" ]]; then
                log_error "Provider version mismatch between environments"
                inconsistency_found=true
            fi
        fi
    done
    
    if [[ "$inconsistency_found" == "true" ]]; then
        return 1
    fi
    
    log_success "Provider versions are consistent across environments"
    log_info "  AWS: $aws_version"
    log_info "  Kubernetes: $kubernetes_version"
    log_info "  Helm: $helm_version"
}

check_terraform_init() {
    local env=$1
    local env_dir="$TERRAFORM_ROOT/environments/$env"
    
    log_info "Testing terraform init for $env environment..."
    
    cd "$env_dir"
    
    # Clean any existing state
    rm -rf .terraform .terraform.lock.hcl
    
    # Test terraform init
    if terraform init -backend=false &> /dev/null; then
        log_success "Terraform init successful for $env environment"
        
        # Clean up
        rm -rf .terraform .terraform.lock.hcl
    else
        log_error "Terraform init failed for $env environment"
        cd - > /dev/null
        return 1
    fi
    
    cd - > /dev/null
}

# ====================================================================
# MAIN VALIDATION ROUTINE
# ====================================================================

main() {
    log_info "Starting Terraform configuration validation..."
    echo
    
    local validation_failed=false
    
    # System requirements
    validate_terraform_version || validation_failed=true
    validate_aws_credentials || validation_failed=true
    echo
    
    # Module structure
    validate_module_structure || validation_failed=true
    echo
    
    # Provider consistency
    validate_provider_versions || validation_failed=true
    echo
    
    # Environment-specific validations
    for env in "${ENVIRONMENTS[@]}"; do
        validate_required_files "$env" || validation_failed=true
        validate_terraform_syntax "$env" || validation_failed=true
        check_terraform_init "$env" || validation_failed=true
        echo
    done
    
    # Final result
    if [[ "$validation_failed" == "true" ]]; then
        log_error "Validation completed with errors"
        exit 1
    else
        log_success "All validations passed! Configuration is ready for deployment"
        echo
        log_info "Next steps:"
        log_info "1. Copy terraform.tfvars.example to terraform.tfvars in each environment"
        log_info "2. Update terraform.tfvars with your specific values"
        log_info "3. Run 'terraform plan' to review changes"
        log_info "4. Run 'terraform apply' to deploy infrastructure"
    fi
}

# Run the validation
main "$@" 