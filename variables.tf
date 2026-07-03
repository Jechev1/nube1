variable "aws_region" {
  type = string
}

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
  default = "dev"
}

variable "s3_bucket_name" {
  type = string
}

variable "waf_rate_limit" {
  type = number
  default = 1000
}

# Variable para el ARN del user pool Cognito (lo pasará el módulo cognito)
variable "cognito_user_pool_arn" {
  type = string
  default = ""
}