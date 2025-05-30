output "valkey_srvless_endpoint" {
  description = "Endpoint URL for the Valkey Serverless cluster"
  value       = aws_elasticache_serverless_cache.valkey.endpoint
}

output "valkey_srvless_security_group_id" {
  description = "Security group ID for Valkey Serverless"
  value       = aws_security_group.valkey.id
}

output "valkey_srvless_port" {
  description = "Port for Valkey Serverless"
  value       = 6379
} 