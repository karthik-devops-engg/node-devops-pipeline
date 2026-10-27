variable "name" {
  type = string
}

variable "role" {
  description = "Server role tag, used by Ansible to group hosts"
  type        = string
}

variable "instance_count" {
  type    = number
  default = 1
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "subnet_ids" {
  type = list(string)
}

variable "security_group_ids" {
  type = list(string)
}

variable "key_name" {
  type = string
}

variable "root_volume_size" {
  type    = number
  default = 10
}
