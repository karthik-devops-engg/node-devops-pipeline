variable "region" {
  description = "AWS region (new AWS experience supports eu-north-1)"
  type        = string
  default     = "eu-north-1"
}

variable "my_ip_cidr" {
  description = "Your public IP in CIDR form, e.g. 203.0.113.10/32"
  type        = string
}

variable "public_key_path" {
  type    = string
  default = "~/.ssh/node-devops.pub"
}

variable "app_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "monitoring_instance_type" {
  description = "ELK needs ~4GB+ RAM"
  type        = string
  default     = "m7i-flex.large"
}
