variable "aws_region" {
  type = string
}

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "s3_bucket_name" {
  type = string
}

variable "waf_rate_limit" {
  type    = number
  default = 1000
}

variable "ses_sender_email" {
  type        = string
  description = "correo que ses usa para mandar las notificaciones"
}
