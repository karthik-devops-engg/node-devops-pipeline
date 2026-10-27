variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "security_group_id" {
  type = string
}

variable "target_instance_ids" {
  type = list(string)
}

variable "target_port" {
  type    = number
  default = 3000
}

variable "health_check_path" {
  type    = string
  default = "/health"
}
