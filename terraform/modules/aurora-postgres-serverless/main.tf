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
  # For Serverless v2, use "provisioned" mode
  engine_mode                     = "provisioned"
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
  
  # Serverless v2 uses serverlessv2_scaling_configuration instead of scaling_configuration
  serverlessv2_scaling_configuration {
    min_capacity = var.min_capacity
    max_capacity = var.max_capacity
  }

  tags = {
    Name = "${var.project_name}-aurora-srvless-cluster"
  }
  
  # AWS best practice: Let AWS manage the actual AZ placement for Aurora clusters
  # - Initially we specify our preferred AZs, but after creation we let AWS optimize placement
  # - Aurora's storage is automatically distributed across AZs regardless of instance placement
  # - AWS may need to adjust AZs for maintenance, capacity optimization, or recovery
  # - This prevents unnecessary cluster recreation during Terraform operations
  lifecycle {
    ignore_changes = [availability_zones]
  }
}

# For Aurora Serverless v2, we need at least one instance with "db.serverless" class
resource "aws_rds_cluster_instance" "aurora_srvless_instance" {
  count                = 1
  identifier           = "${var.project_name}-aurora-srvless-instance-${count.index}"
  cluster_identifier   = aws_rds_cluster.aurora_srvless.id
  instance_class       = "db.serverless"
  engine               = aws_rds_cluster.aurora_srvless.engine
  engine_version       = aws_rds_cluster.aurora_srvless.engine_version
  db_subnet_group_name = aws_db_subnet_group.aurora_srvless.name
  publicly_accessible  = false

  tags = {
    Name = "${var.project_name}-aurora-srvless-instance-${count.index}"
  }
} 