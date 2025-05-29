output "cluster_endpoint" {
  description = "The cluster endpoint for the Aurora cluster"
  value       = aws_rds_cluster.aurora.endpoint
}

output "reader_endpoint" {
  description = "The reader endpoint for the Aurora cluster"
  value       = aws_rds_cluster.aurora.reader_endpoint
}

output "cluster_port" {
  description = "The port on which the Aurora cluster accepts connections"
  value       = aws_rds_cluster.aurora.port
}

output "cluster_identifier" {
  description = "The identifier of the Aurora cluster"
  value       = aws_rds_cluster.aurora.cluster_identifier
}

output "security_group_id" {
  description = "The ID of the security group created for the Aurora cluster"
  value       = aws_security_group.aurora.id
}

output "database_name" {
  description = "The name of the default database"
  value       = aws_rds_cluster.aurora.database_name
}

output "master_username" {
  description = "The master username for the database"
  value       = aws_rds_cluster.aurora.master_username
}

output "cluster_resource_id" {
  description = "The Resource ID of the Aurora Cluster"
  value       = aws_rds_cluster.aurora.cluster_resource_id
} 