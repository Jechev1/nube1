output "catalog_lambda_function_name" {
  value = aws_lambda_function.catalog.function_name
}

output "catalog_lambda_arn" {
  value = aws_lambda_function.catalog.arn
}

output "stores_table_name" {
  value = aws_dynamodb_table.stores.name
}

output "products_table_name" {
  value = aws_dynamodb_table.products.name
}

output "products_table_arn" {
  value = aws_dynamodb_table.products.arn
}

output "cart_table_name" {
  value = aws_dynamodb_table.cart.name
}
