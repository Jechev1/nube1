data "aws_caller_identity" "current" {}

resource "random_password" "jwt_secret" {
  length  = 64
  special = false
}

resource "aws_secretsmanager_secret" "jwt_secret" {
  name        = "${var.project_name}-${var.environment}-jwt-secret"
  description = "Clave HMAC para firmar tokens JWT del Auth Service"
}

resource "aws_secretsmanager_secret_version" "jwt_secret" {
  secret_id     = aws_secretsmanager_secret.jwt_secret.id
  secret_string = random_password.jwt_secret.result
}

resource "aws_dynamodb_table" "users" {
  name         = "${var.project_name}-${var.environment}-Users"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "user_id"

  attribute {
    name = "user_id"
    type = "S"
  }

  attribute {
    name = "email"
    type = "S"
  }

  global_secondary_index {
    name            = "email-index"
    hash_key        = "email"
    range_key       = "user_id"
    projection_type = "ALL"
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_iam_policy" "auth_dynamodb" {
  name = "${var.project_name}-${var.environment}-auth-dynamodb"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query"
        ]
        Resource = [
          aws_dynamodb_table.users.arn,
          "${aws_dynamodb_table.users.arn}/index/*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "auth_secrets" {
  name = "${var.project_name}-${var.environment}-auth-secrets"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          aws_secretsmanager_secret.jwt_secret.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "auth_dynamodb_attach" {
  role       = var.lambda_role_name
  policy_arn = aws_iam_policy.auth_dynamodb.arn
}

resource "aws_iam_role_policy_attachment" "auth_secrets_attach" {
  role       = var.lambda_role_name
  policy_arn = aws_iam_policy.auth_secrets.arn
}

# Instala las dependencias de requirements.txt (bcrypt, PyJWT) como binarios
# compatibles con el runtime de Lambda (manylinux2014_x86_64 / py3.12), sin
# importar el SO de quien corre "terraform apply".
resource "null_resource" "install_layer_deps" {
  triggers = {
    requirements_hash = filesha256("${path.module}/lambda/requirements.txt")
  }

  provisioner "local-exec" {
    # Sin comillas alrededor de los paths: en Windows, local-exec corre via
    # "cmd /C <command>" y las comillas anidadas llegan literales al
    # argumento (pip terminaba buscando el archivo '"...requirements.txt"').
    # Los paths de este proyecto no tienen espacios, asi que es seguro.
    command = "python -m pip install --platform manylinux2014_x86_64 --python-version 3.12 --implementation cp --abi cp312 --only-binary=:all: --upgrade --target ${path.module}/layer/python -r ${path.module}/lambda/requirements.txt"
  }
}

data "archive_file" "auth_layer" {
  type        = "zip"
  source_dir  = "${path.module}/layer"
  output_path = "${path.module}/layer.zip"
  depends_on  = [null_resource.install_layer_deps]
}

resource "aws_lambda_layer_version" "auth_deps" {
  layer_name          = "${var.project_name}-${var.environment}-auth-deps"
  filename            = data.archive_file.auth_layer.output_path
  source_code_hash    = data.archive_file.auth_layer.output_base64sha256
  compatible_runtimes = ["python3.12"]
}

data "archive_file" "auth_lambda" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "auth" {
  function_name    = "${var.project_name}-${var.environment}-auth"
  role             = var.lambda_role_arn
  handler          = "index.handler"
  runtime          = "python3.12"
  filename         = data.archive_file.auth_lambda.output_path
  source_code_hash = data.archive_file.auth_lambda.output_base64sha256
  layers           = [aws_lambda_layer_version.auth_deps.arn]
  timeout          = 30
  memory_size      = 256

  environment {
    variables = {
      USERS_TABLE          = aws_dynamodb_table.users.name
      JWT_SECRET_ARN       = aws_secretsmanager_secret.jwt_secret.arn
      JWT_ACCESS_EXPIRY_H  = var.jwt_access_expiry_hours
      JWT_REFRESH_EXPIRY_D = var.jwt_refresh_expiry_days
      CORS_ALLOWED_ORIGINS = var.cors_allowed_origins
    }
  }

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_lambda_permission" "apigateway_auth" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auth.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.aws_region}:${var.account_id}:${var.api_gateway_id}/*"
}

# Lambda Authorizer (TOKEN) reutilizado por otras rutas/modulos (P3, P4, P5, P6)
# para proteger sus endpoints con el mismo JWT emitido por este servicio.
resource "aws_api_gateway_authorizer" "jwt" {
  name                             = "${var.project_name}-${var.environment}-jwt-authorizer"
  rest_api_id                      = var.api_gateway_id
  type                             = "TOKEN"
  authorizer_uri                   = aws_lambda_function.auth.invoke_arn
  identity_source                  = "method.request.header.Authorization"
  authorizer_result_ttl_in_seconds = 300
}

resource "aws_lambda_permission" "apigateway_authorizer" {
  statement_id  = "AllowAPIGatewayInvokeAuthorizer"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auth.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.aws_region}:${var.account_id}:${var.api_gateway_id}/authorizers/${aws_api_gateway_authorizer.jwt.id}"
}

resource "aws_api_gateway_resource" "auth" {
  rest_api_id = var.api_gateway_id
  parent_id   = var.api_gateway_root_id
  path_part   = "auth"
}

resource "aws_api_gateway_resource" "auth_proxy" {
  rest_api_id = var.api_gateway_id
  parent_id   = aws_api_gateway_resource.auth.id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "auth_any" {
  rest_api_id   = var.api_gateway_id
  resource_id   = aws_api_gateway_resource.auth_proxy.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "auth_lambda" {
  rest_api_id             = var.api_gateway_id
  resource_id             = aws_api_gateway_resource.auth_proxy.id
  http_method             = aws_api_gateway_method.auth_any.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.auth.invoke_arn
}

resource "aws_api_gateway_method" "auth_root" {
  rest_api_id   = var.api_gateway_id
  resource_id   = aws_api_gateway_resource.auth.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "auth_lambda_root" {
  rest_api_id             = var.api_gateway_id
  resource_id             = aws_api_gateway_resource.auth.id
  http_method             = aws_api_gateway_method.auth_root.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.auth.invoke_arn
}
