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

variable "v1_resource_id" {
  type        = string
  description = "ID del recurso /v1 (modulo apigateway), padre de /v1/stores, /v1/products, /v1/cart"
}

variable "authorizer_id" {
  type        = string
  description = "ID del Lambda Authorizer JWT (modulo auth), para proteger mutaciones y el carrito"
}

variable "lambda_role_arn" {
  type        = string
  description = "ARN del rol IAM compartido para Lambdas (del modulo iam)"
}

variable "lambda_role_name" {
  type        = string
  description = "Nombre del rol IAM para adjuntar politicas"
}
