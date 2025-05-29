output "redis_endpoint" {
  description = "The primary endpoint for the Redis cluster"
  value       = aws_elasticache_replication_group.redis.primary_endpoint_address
}

output "redis_security_group_id" {
  description = "The ID of the Redis security group"
  value       = aws_security_group.redis.id
}

output "redis_port" {
  description = "The port the Redis cluster is listening on"
  value       = aws_elasticache_replication_group.redis.port
}

output "redis_cluster_id" {
  description = "The ID of the Redis cluster"
  value       = aws_elasticache_replication_group.redis.id
} 