variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "project_name" {
  type    = string
  default = "garbo"
}

variable "environment" {
  type    = string
  default = "prod"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "key_name" {
  type        = string
  description = "Existing EC2 key pair in your AWS account/region."
}

variable "ssh_allowed_cidr" {
  type        = string
  description = "Your public IP with /32 suffix, e.g. 203.0.113.10/32"
}

variable "ssm_parameter_prefix" {
  type    = string
  default = "/garbo/prod"
}
