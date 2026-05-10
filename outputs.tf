output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.ec2.alb_dns_name
}

output "bastion_public_ip" {
  description = "Public IP of the Bastion Host"
  value       = module.ec2.bastion_public_ip
}

output "rds_endpoint" {
  description = "RDS MySQL endpoint"
  value       = module.rds.db_endpoint
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = module.iam.ecr_repository_url
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}
