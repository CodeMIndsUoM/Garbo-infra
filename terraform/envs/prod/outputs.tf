output "ec2_public_ip" {
  description = "Public IP of the new Garbo app server"
  value       = module.compute.public_ip
}

output "ec2_public_dns" {
  description = "Public DNS of the new Garbo app server"
  value       = module.compute.public_dns
}

output "backend_ecr_url" {
  value = module.registry.backend_repository_url
}

output "frontend_ecr_url" {
  value = module.registry.frontend_repository_url
}

output "ssm_parameter_prefix" {
  value = module.secrets.ssm_parameter_prefix
}

output "ssh_command" {
  value = "ssh -i ~/.ssh/<your-key>.pem ubuntu@${module.compute.public_ip}"
}
