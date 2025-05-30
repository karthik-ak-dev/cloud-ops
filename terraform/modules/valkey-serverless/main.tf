resource "aws_elasticache_subnet_group" "valkey" {
  name       = "${var.project_name}-valkey-srvless-subnet-group"
  subnet_ids = var.private_subnet_ids
}

resource "aws_security_group" "valkey" {
  name        = "${var.project_name}-valkey-srvless-sg"
  description = "Security group for Valkey Serverless cluster"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    description = "Valkey Serverless port"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-valkey-srvless-sg"
  }
}

resource "aws_elasticache_parameter_group" "valkey" {
  name   = "${var.project_name}-valkey-srvless-params"
  family = "valkey7"
}

resource "aws_elasticache_serverless_cache" "valkey" {
  engine                = "valkey"
  name                  = "${var.project_name}-valkey-srvless"
  description           = "Valkey Serverless for ${var.project_name}"
  
  cache_usage_limits {
    data_storage {
      maximum = var.max_storage_gb
      unit    = "GB"
    }
    ecpu_per_second {
      maximum = var.max_ecpu_per_second
    }
  }
  
  security_group_ids    = [aws_security_group.valkey.id]
  subnet_ids            = var.private_subnet_ids
  snapshot_retention_limit = 7
  
  # Authentication
  user_group_id         = aws_elasticache_user_group.valkey.user_group_id

  tags = {
    Name = "${var.project_name}-valkey-srvless"
  }
}

# Create a user for authentication
resource "aws_elasticache_user" "valkey_admin" {
  user_id       = "${var.project_name}-valkey-srvless-admin"
  user_name     = "admin"
  access_string = "on ~* +@all"
  authentication_mode {
    type      = "password"
    passwords = [var.auth_token]
  }
  engine = "valkey"
}

# Create user group for authentication
resource "aws_elasticache_user_group" "valkey" {
  user_group_id = "${var.project_name}-valkey-srvless-users"
  engine        = "valkey"
  user_ids      = [aws_elasticache_user.valkey_admin.user_id]
} 