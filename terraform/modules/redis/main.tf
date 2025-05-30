resource "aws_elasticache_subnet_group" "redis" {
  name       = "${var.project_name}-redis-subnet-group"
  subnet_ids = var.private_subnet_ids
}

resource "aws_security_group" "redis" {
  name        = "${var.project_name}-redis-sg"
  description = "Security group for Redis cluster"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    description = "Redis port"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-redis-sg"
  }
}

# Extract major version from the engine_version (e.g., "7.0" -> "7")
locals {
  # Get major version number for parameter group family
  redis_major_version = split(".", var.engine_version)[0]
}

resource "aws_elasticache_parameter_group" "redis" {
  name   = "${var.project_name}-redis-params"
  family = "redis${local.redis_major_version}"
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id          = "${var.project_name}-redis"
  description                   = "Redis cluster for ${var.project_name}"
  engine_version                = var.engine_version
  node_type                     = var.node_type
  port                          = 6379
  parameter_group_name          = aws_elasticache_parameter_group.redis.name
  subnet_group_name             = aws_elasticache_subnet_group.redis.name
  security_group_ids            = [aws_security_group.redis.id]
  automatic_failover_enabled    = var.node_count > 1 ? true : false
  num_cache_clusters            = var.node_count
  multi_az_enabled              = var.node_count > 1 ? true : false
  at_rest_encryption_enabled    = true
  transit_encryption_enabled    = true
  auth_token                    = var.auth_token

  tags = {
    Name = "${var.project_name}-redis"
  }
} 