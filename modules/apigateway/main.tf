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

# Las rutas reales bajo /v1 (stores, products, cart, etc.) las crea cada
# modulo de feature (catalog, orders, ...) usando el output v1_resource_id,
# protegidas con el Lambda Authorizer JWT del modulo auth.

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