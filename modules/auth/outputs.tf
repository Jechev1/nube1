output "auth_lambda_function_name" {
  value = aws_lambda_function.auth.function_name
}

output "auth_lambda_arn" {
  value = aws_lambda_function.auth.arn
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.users.name
}

output "dynamodb_table_arn" {
  value = aws_dynamodb_table.users.arn
}

output "jwt_secret_arn" {
  value = aws_secretsmanager_secret.jwt_secret.arn
}

output "jwt_secret_name" {
  value = aws_secretsmanager_secret.jwt_secret.name
}

output "authorizer_id" {
  description = "ID del Lambda Authorizer JWT, para proteger rutas de otros modulos (P3, P4, P5, P6)"
  value       = aws_api_gateway_authorizer.jwt.id
}