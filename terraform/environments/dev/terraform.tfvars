# Client-specific configuration
project_name = "dev-client-name"  # Replace client-name with your client name
region       = "eu-west-3"
vpc_cidr     = "10.0.0.0/16"

# Feature flags
deploy_aurora = false  # Set to false to skip Aurora PostgreSQL deployment
deploy_aurora_srvless = false  # Set to false to skip Aurora PostgreSQL Serverless deployment
deploy_redis = false   # Set to false to skip Redis ElastiCache deployment
deploy_valkey_srvless = false  # Set to false to skip Valkey Serverless deployment
deploy_ecr = true     # Set to false to skip ECR repositories deployment
deploy_eks = true     # Set to false to skip EKS cluster deployment
deploy_alb_controller = true  # Set to false to skip ALB controller deployment

# Redis Configuration
redis_node_type  = "cache.t3.small"
redis_node_count = 1
redis_auth_token = "your-redis-auth-token-here"

# Valkey Serverless Configuration
valkey_srvless_max_storage_gb = 10
valkey_srvless_max_ecpu_per_second = 20000
valkey_srvless_auth_token = "your-valkey-srvless-auth-token-here"

# Aurora PostgreSQL Configuration
postgres_instance_class = "db.t3.medium"
postgres_instance_count = 1
postgres_engine_version = "16.6"
postgres_database_name  = "postgresdb"
postgres_master_username = "postgres"
postgres_master_password = "your-strong-password-here"
postgres_deletion_protection = false  # For dev environment, disable deletion protection
postgres_skip_final_snapshot = true   # For dev environment, skip final snapshot on deletion

# Aurora PostgreSQL Serverless Configuration
postgres_srvless_engine_version = "16.6"  # Aurora Serverless v2 supports PostgreSQL 16.x
postgres_srvless_database_name = "postgresdb"
postgres_srvless_master_username = "postgres"
postgres_srvless_master_password = "your-srvless-strong-password-here"
postgres_srvless_auto_pause = true
postgres_srvless_max_capacity = 4
postgres_srvless_min_capacity = 1
postgres_srvless_seconds_until_auto_pause = 300
postgres_srvless_deletion_protection = false  # For dev environment, disable deletion protection
postgres_srvless_skip_final_snapshot = true   # For dev environment, skip final snapshot on deletion

# EKS Configuration
kubernetes_version   = "1.33"  # Now supported with AL2023_x86_64 AMI
eks_instance_type    = "t3.medium"
eks_desired_capacity = 1
eks_max_capacity     = 4
eks_min_capacity     = 1

# CI/CD Configuration
create_ci_user = true
create_cd_user = true
create_access_keys = true 