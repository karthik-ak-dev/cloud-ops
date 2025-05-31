output "aurora_srvless_cluster_id" {
  description = "ID of the Aurora Serverless cluster"
  value       = aws_rds_cluster.aurora_srvless.id
}

output "aurora_srvless_cluster_endpoint" {
  description = "Writer endpoint for the Aurora Serverless cluster"
  value       = aws_rds_cluster.aurora_srvless.endpoint
}

output "aurora_srvless_cluster_reader_endpoint" {
  description = "Reader endpoint for the Aurora Serverless cluster"
  value       = aws_rds_cluster.aurora_srvless.reader_endpoint
}

output "aurora_srvless_cluster_port" {
  description = "Port used by the Aurora Serverless cluster"
  value       = aws_rds_cluster.aurora_srvless.port
}

output "aurora_srvless_database_name" {
  description = "Name of the default database"
  value       = aws_rds_cluster.aurora_srvless.database_name
}

output "aurora_srvless_master_username" {
  description = "Master username for the Aurora Serverless cluster"
  value       = aws_rds_cluster.aurora_srvless.master_username
}

output "aurora_srvless_security_group_id" {
  description = "ID of the security group for the Aurora Serverless cluster"
  value       = aws_security_group.aurora_srvless.id
} 