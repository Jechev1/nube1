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
  description = "ID del recurso /v1 (modulo apigateway), padre de /v1/orders"
}

variable "authorizer_id" {
  type        = string
  description = "ID del Lambda Authorizer JWT (modulo auth), para proteger todas las rutas de pedidos"
}

variable "lambda_role_arn" {
  type        = string
  description = "ARN del rol IAM compartido para Lambdas (del modulo iam)"
}

variable "lambda_role_name" {
  type        = string
  description = "Nombre del rol IAM para adjuntar politicas"
}

variable "cart_table_name" {
  type        = string
  description = "Nombre de la tabla Cart (modulo catalog), para armar el pedido al hacer checkout"
}

variable "products_table_name" {
  type        = string
  description = "Nombre de la tabla Products (modulo catalog), para validar stock/precio al hacer checkout"
}

variable "event_bus_name" {
  type        = string
  default     = "default"
  description = "Bus de EventBridge donde se publican OrderCreated/OrderStatusChanged. P5 puede pasar aqui el nombre de su bus propio cuando lo cree; hasta entonces usa el bus 'default' de la cuenta."
}
