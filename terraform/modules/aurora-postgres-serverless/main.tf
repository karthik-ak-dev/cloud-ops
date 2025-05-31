resource "aws_db_subnet_group" "aurora_srvless" {
  name       = "${var.project_name}-aurora-srvless-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${var.project_name}-aurora-srvless-subnet-group"
  }
}

resource "aws_security_group" "aurora_srvless" {
  name        = "${var.project_name}-aurora-srvless-sg"
  description = "Security group for Aurora PostgreSQL Serverless cluster"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = var.port
    to_port     = var.port
    protocol    = "tcp"
    description = "PostgreSQL Serverless port"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-aurora-srvless-sg"
  }
}

# Extract major version from the full version string (e.g., "16.6" -> "16")
# Also handles edge cases like versions without periods (e.g., "16" -> "16")
locals {
  # First check if engine_version contains a period, if so split at first period
  # If not (or if empty), use the entire string as the major version
  major_version = length(regexall("\\.", var.engine_version)) > 0 ? split(".", var.engine_version)[0] : var.engine_version
}

resource "aws_rds_cluster_parameter_group" "aurora_srvless" {
  name   = "${var.project_name}-aurora-srvless-param-group"
  family = "aurora-postgresql${local.major_version}"

  parameter {
    name  = "log_statement"
    value = "none"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }
}

resource "aws_rds_cluster" "aurora_srvless" {
  cluster_identifier              = "${var.project_name}-aurora-srvless-cluster"
  engine                          = "aurora-postgresql"
  engine_version                  = var.engine_version
  engine_mode                     = "serverless"
  availability_zones              = var.availability_zones
  database_name                   = var.database_name
  master_username                 = var.master_username
  master_password                 = var.master_password
  backup_retention_period         = var.backup_retention_period
  preferred_backup_window         = var.preferred_backup_window
  preferred_maintenance_window    = var.preferred_maintenance_window
  db_subnet_group_name            = aws_db_subnet_group.aurora_srvless.name
  vpc_security_group_ids          = [aws_security_group.aurora_srvless.id]
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.aurora_srvless.name
  port                            = var.port
  storage_encrypted               = true
  deletion_protection             = var.deletion_protection
  skip_final_snapshot             = var.skip_final_snapshot
  final_snapshot_identifier       = var.skip_final_snapshot ? null : "${var.project_name}-aurora-srvless-final-snapshot"
  
  scaling_configuration {
    auto_pause               = var.auto_pause
    max_capacity             = var.max_capacity
    min_capacity             = var.min_capacity
    seconds_until_auto_pause = var.seconds_until_auto_pause
    timeout_action           = var.timeout_action
  }

  tags = {
    Name = "${var.project_name}-aurora-srvless-cluster"
  }
} 