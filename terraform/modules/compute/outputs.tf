output "instance_id" {
  value = aws_instance.app.id
}

output "public_ip" {
  description = "Stable Elastic IP (same after stop/start)"
  value       = aws_eip.app.public_ip
}

output "elastic_ip_allocation_id" {
  value = aws_eip.app.id
}

output "public_dns" {
  value = aws_instance.app.public_dns
}

output "iam_role_name" {
  value = aws_iam_role.ec2.name
}
