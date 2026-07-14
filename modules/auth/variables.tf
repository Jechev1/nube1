variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "account_id" {
  type = string
}

variable "api_gateway_id" {
  type = string
}

variable "api_gateway_root_id" {
  type = string
}

variable "lambda_role_arn" {
  type        = string
  description = "ARN del rol IAM compartido para Lambdas (del modulo iam)"
}

variable "lambda_role_name" {
  type        = string
  description = "Nombre del rol IAM para adjuntar politicas"
}

variable "jwt_access_expiry_hours" {
  type    = number
  default = 1
}

variable "jwt_refresh_expiry_days" {
  type    = number
  default = 7
}

variable "cors_allowed_origins" {
  type    = string
  default = "*"
}
