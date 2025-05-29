output "helm_release_name" {
  description = "Name of the Helm release for the AWS Load Balancer Controller"
  value       = helm_release.aws_load_balancer_controller.name
}

output "helm_release_status" {
  description = "Status of the Helm release for the AWS Load Balancer Controller"
  value       = helm_release.aws_load_balancer_controller.status
} 