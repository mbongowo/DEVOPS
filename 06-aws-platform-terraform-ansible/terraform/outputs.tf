output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "VPC id"
}

output "app_private_ips" {
  value       = module.app[*].private_ip
  description = "Private IPs of the app instances (Ansible inventory targets)"
}

output "db_endpoint" {
  value       = module.rds.db_instance_endpoint
  description = "RDS endpoint"
  sensitive   = true
}
