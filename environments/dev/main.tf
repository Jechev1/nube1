data "aws_caller_identity" "current" {}

module "cognito" {
  source = "../../modules/cognito"
  project_name = var.project_name
  environment  = var.environment
}

module "s3" {
  source = "../../modules/s3"
  bucket_name   = var.s3_bucket_name
  project_name  = var.project_name
  environment   = var.environment
}

module "cloudfront" {
  source = "../../modules/cloudfront"
  project_name        = var.project_name
  environment         = var.environment
  bucket_name         = var.s3_bucket_name
  s3_website_endpoint = module.s3.website_endpoint
  web_acl_id          = module.waf.web_acl_arn
}

module "waf" {
  source = "../../modules/waf"
  project_name   = var.project_name
  environment    = var.environment
  rate_limit     = var.waf_rate_limit
  cloudfront_arn = module.cloudfront.cloudfront_arn
}

module "iam" {
  source = "../../modules/iam"
  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region
  account_id   = data.aws_caller_identity.current.account_id
}

module "apigateway" {
  source = "../../modules/apigateway"
  project_name          = var.project_name
  environment           = var.environment
  cognito_user_pool_arn = module.cognito.user_pool_arn
}

module "auth" {
  source     = "../../modules/auth"
  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region
  account_id   = data.aws_caller_identity.current.account_id
  api_gateway_id      = module.apigateway.api_id
  api_gateway_root_id = module.apigateway.api_root_id
  lambda_role_arn     = module.iam.lambda_role_arn
  lambda_role_name    = module.iam.lambda_role_name
}

resource "aws_api_gateway_deployment" "main" {
  rest_api_id = module.apigateway.api_id
  triggers = {
    redeploy = sha1(jsonencode([
      module.apigateway.api_id,
      module.auth.auth_lambda_function_name,
    ]))
  }
  depends_on = [
    module.apigateway,
    module.auth,
  ]
}

resource "aws_api_gateway_stage" "main" {
  deployment_id = aws_api_gateway_deployment.main.id
  rest_api_id   = module.apigateway.api_id
  stage_name    = var.environment
}