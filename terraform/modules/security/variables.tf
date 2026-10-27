variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "ssh_cidr" {
  description = "CIDR allowed to SSH and view dashboards (your IP/32)"
  type        = string
}

variable "app_port" {
  type    = number
  default = 3000
}
