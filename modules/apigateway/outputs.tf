output "api_id" {
  value = aws_api_gateway_rest_api.api.id
}

output "api_root_id" {
  value = aws_api_gateway_rest_api.api.root_resource_id
}

output "api_url" {
  value = aws_api_gateway_rest_api.api.execution_arn
}

output "api_key_value" {
  value = aws_api_gateway_api_key.api_key.value
}