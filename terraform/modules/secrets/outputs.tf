output "ssm_parameter_prefix" {
  value = var.ssm_parameter_prefix
}

output "ssm_parameter_arns" {
  value = [
    aws_ssm_parameter.jwt_secret.arn,
    aws_ssm_parameter.db_url.arn,
    aws_ssm_parameter.db_username.arn,
    aws_ssm_parameter.db_password.arn,
    aws_ssm_parameter.cloudinary_cloud_name.arn,
    aws_ssm_parameter.cloudinary_api_key.arn,
    aws_ssm_parameter.cloudinary_api_secret.arn,
  ]
}
