variable "project_name" {
  type = string
}

variable "ec2_instance_id" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
