# URL de invocación de la API Gateway
output "api_url" {
  value = module.apigateway.api_url
}

# API Key (márcala como sensible para que no se vea en los logs)
output "api_key_value" {
  value     = module.apigateway.api_key_value
  sensitive = true
}

# Dominio de CloudFront
output "cloudfront_domain_name" {
  value = module.cloudfront.cloudfront_domain_name
}

# ID del User Pool de Cognito
output "user_pool_id" {
  value = module.cognito.user_pool_id
}

# ID del Cliente de Cognito
output "client_id" {
  value = module.cognito.client_id
}