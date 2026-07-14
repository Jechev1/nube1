variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "cognito_user_pool_arn" {
  type        = string
  description = "ARN del user pool de Cognito que usará el authorizer de API Gateway"
}