variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "az_a" {
  type = string
}

variable "az_b" {
  type = string
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_cidr_a" {
  type    = string
  default = "10.0.1.0/24"
}

variable "public_subnet_cidr_b" {
  type    = string
  default = "10.0.4.0/24"
}

variable "private_subnet_cidr_a" {
  type    = string
  default = "10.0.2.0/24"
}

variable "private_subnet_cidr_b" {
  type    = string
  default = "10.0.3.0/24"
}
