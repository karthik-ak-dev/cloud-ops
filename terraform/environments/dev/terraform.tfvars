# Client-specific configuration
project_name = "dev-client-name"  # Replace client-name with your client name
region       = "eu-west-3"
vpc_cidr     = "10.0.0.0/16"

# Feature flags
deploy_aurora = false  # Set to false to skip Aurora PostgreSQL deployment
deploy_redis = false   # Set to false to skip Redis ElastiCache deployment
deploy_ecr = false     # Set to false to skip ECR repositories deployment
deploy_eks = false     # Set to false to skip EKS cluster deployment
deploy_alb_controller = false  # Set to false to skip ALB controller deployment

# Redis Configuration
redis_node_type  = "cache.t3.small"
redis_node_count = 1
redis_auth_token = "your-redis-auth-token-here"

# Aurora PostgreSQL Configuration
postgres_instance_class = "db.t3.medium"
postgres_instance_count = 1
postgres_engine_version = "13.7"
postgres_database_name  = "postgres-db"
postgres_master_username = "postgres"
postgres_master_password = "your-strong-password-here"

# EKS Configuration
kubernetes_version   = "1.28"
eks_instance_type    = "t3.medium"
eks_desired_capacity = 1
eks_max_capacity     = 4
eks_min_capacity     = 1 