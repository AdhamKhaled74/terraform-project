variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "asg_name" {
  type = string
}

variable "alb_arn_suffix" {
  type = string
}

variable "alert_email" {
  type    = string
  default = ""
}

variable "asg_policy_arn" {
  type = string
}

variable "cpu_threshold" {
  type    = number
  default = 70
}
