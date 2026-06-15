variable "project_name" {
  type = string
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  type    = string
  default = "10.0.1.0/24"
}

variable "ssh_allowed_cidr" {
  type        = string
  description = "Your public IP as /32 — SSH access only from this address."
}

variable "tags" {
  type    = map(string)
  default = {}
}
