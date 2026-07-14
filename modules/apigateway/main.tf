resource "aws_api_gateway_rest_api" "api" {
  name        = "${var.project_name}-${var.environment}-api"
  description = "API REST para CloudShop"
}

# Recurso raíz /v1
resource "aws_api_gateway_resource" "v1" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "v1"
}

# Authorizer Cognito para proteger rutas de feature modules
resource "aws_api_gateway_authorizer" "cognito" {
  name          = "${var.project_name}-authorizer"
  rest_api_id   = aws_api_gateway_rest_api.api.id
  type          = "COGNITO_USER_POOLS"
  identity_source = "method.request.header.Authorization"
  provider_arns = [var.cognito_user_pool_arn]
}

# API Key
resource "aws_api_gateway_api_key" "api_key" {
  name    = "${var.project_name}-${var.environment}-api-key"
  enabled = true
}

# Usage Plan
resource "aws_api_gateway_usage_plan" "usage_plan" {
  name = "${var.project_name}-${var.environment}-usage-plan"
  throttle_settings {
    burst_limit = 20
    rate_limit  = 10
  }
}

resource "aws_api_gateway_usage_plan_key" "usage_plan_key" {
  key_id        = aws_api_gateway_api_key.api_key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.usage_plan.id
}