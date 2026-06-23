output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS API server endpoint"
  value       = module.eks.cluster_endpoint
}

output "vpc_id" {
  description = "VPC id"
  value       = module.vpc.vpc_id
}

output "ecr_repository_urls" {
  description = "ECR repository URLs per tier"
  value       = { for k, r in aws_ecr_repository.app : k => r.repository_url }
}
