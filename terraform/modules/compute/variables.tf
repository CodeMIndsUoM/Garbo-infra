variable "project_name" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "security_group_id" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "key_name" {
  type        = string
  description = "Existing EC2 key pair name in this AWS region."
}

variable "ssm_parameter_prefix" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
