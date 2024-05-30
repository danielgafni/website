output "cluster_arn" {
  description = "Cluster ARN "
  value       = module.eks.cluster_arn
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ids attached to the cluster control plane"
  value       = module.eks.cluster_security_group_id
}

output "cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = module.eks.cluster_name
}

output "oidc_provider_arn" {
  description = "OIDC provider ARN"
  value = module.eks.oidc_provider_arn
}

output "cluster_subdomain" {
  description = "Cluster subdomain (for Traefik)"
  value = local.cluster_subdomain
}

output "cert_manager_installed" {
  description = "if Cert Manager is installed in the cluster"
  value = var.install_cert_manager
}

output "traefik_installed" {
  description = "if Traefik is installed in the cluster"
  value = var.install_traefik
}
