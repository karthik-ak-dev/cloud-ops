output "helm_release_name" {
  description = "Name of the Helm release for the AWS Load Balancer Controller"
  value       = helm_release.aws_load_balancer_controller.name
}

output "helm_release_status" {
  description = "Status of the Helm release for the AWS Load Balancer Controller"
  value       = helm_release.aws_load_balancer_controller.status
}

output "alb_security_group_id" {
  description = "ID of the ALB security group created by this module"
  value       = aws_security_group.alb.id
}

output "controller_ready" {
  description = "Indicates if ALB controller is ready (has running pods)"
  value       = length(data.kubernetes_pods.alb_controller_pods.pods) > 0
}

output "running_pods_count" {
  description = "Number of running ALB controller pods"
  value       = length(data.kubernetes_pods.alb_controller_pods.pods)
}

output "helm_release_version" {
  description = "Version of the deployed Helm release"
  value       = data.helm_release.self_status.version
}

output "deployment_timestamp" {
  description = "Timestamp when ALB controller was deployed"
  value       = helm_release.aws_load_balancer_controller.status == "deployed" ? timestamp() : null
} 