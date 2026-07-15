output "orders_lambda_function_name" {
  value = aws_lambda_function.orders.function_name
}

output "orders_lambda_arn" {
  value = aws_lambda_function.orders.arn
}

output "orders_table_name" {
  value = aws_dynamodb_table.orders.name
}

output "orders_table_arn" {
  value = aws_dynamodb_table.orders.arn
}
