variable "project_name" {
  type = string
}

variable "ssm_parameter_prefix" {
  type    = string
  default = "/garbo/prod"
}

variable "tags" {
  type    = map(string)
  default = {}
}
