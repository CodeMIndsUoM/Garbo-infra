resource "aws_ssm_parameter" "jwt_secret" {
  name        = "${var.ssm_parameter_prefix}/jwt-secret"
  description = "JWT signing secret for Garbo backend"
  type        = "SecureString"
  value       = "REPLACE_ME_AFTER_APPLY"

  tags = var.tags

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "db_url" {
  name        = "${var.ssm_parameter_prefix}/db-url"
  description = "Neon PostgreSQL JDBC URL"
  type        = "SecureString"
  value       = "REPLACE_ME_AFTER_APPLY"

  tags = var.tags

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "db_username" {
  name        = "${var.ssm_parameter_prefix}/db-username"
  description = "Neon PostgreSQL username"
  type        = "SecureString"
  value       = "REPLACE_ME_AFTER_APPLY"

  tags = var.tags

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "db_password" {
  name        = "${var.ssm_parameter_prefix}/db-password"
  description = "Neon PostgreSQL password"
  type        = "SecureString"
  value       = "REPLACE_ME_AFTER_APPLY"

  tags = var.tags

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "cloudinary_cloud_name" {
  name        = "${var.ssm_parameter_prefix}/cloudinary-cloud-name"
  description = "Cloudinary cloud name"
  type        = "SecureString"
  value       = "REPLACE_ME_AFTER_APPLY"

  tags = var.tags

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "cloudinary_api_key" {
  name        = "${var.ssm_parameter_prefix}/cloudinary-api-key"
  description = "Cloudinary API key"
  type        = "SecureString"
  value       = "REPLACE_ME_AFTER_APPLY"

  tags = var.tags

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "cloudinary_api_secret" {
  name        = "${var.ssm_parameter_prefix}/cloudinary-api-secret"
  description = "Cloudinary API secret"
  type        = "SecureString"
  value       = "REPLACE_ME_AFTER_APPLY"

  tags = var.tags

  lifecycle {
    ignore_changes = [value]
  }
}
