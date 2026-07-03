# Rol para todas las Lambdas (se puede usar uno solo, pero luego se pueden crear roles separados)
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-${var.environment}-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Política base para logs
resource "aws_iam_role_policy_attachment" "cloudwatch_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Políticas para DynamoDB (cada tabla)
locals {
  tables = ["Products", "Stores", "Orders", "Cart", "Users"]
}

resource "aws_iam_policy" "dynamodb" {
  for_each = toset(local.tables)
  name     = "${var.project_name}-${var.environment}-dynamodb-${each.value}"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Scan",
          "dynamodb:Query"
        ]
        Resource = [
          "arn:aws:dynamodb:${var.aws_region}:${var.account_id}:table/${each.value}",
          "arn:aws:dynamodb:${var.aws_region}:${var.account_id}:table/${each.value}/index/*"
        ]
      }
    ]
  })
}

# Adjuntar cada política al rol (esto hace que el rol tenga permisos sobre TODAS las tablas, lo cual no es mínimo privilegio si una Lambda solo necesita una tabla)
# Para cumplir, se deberían crear roles separados. Por simplicidad, adjuntamos todas, pero en la práctica cada Lambda usaría un rol diferente.
resource "aws_iam_role_policy_attachment" "dynamodb_attach" {
  for_each   = aws_iam_policy.dynamodb
  role       = aws_iam_role.lambda_role.name
  policy_arn = each.value.arn
}

# Política para EventBridge (put events)
resource "aws_iam_policy" "eventbridge" {
  name = "${var.project_name}-${var.environment}-eventbridge-put"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "events:PutEvents"
        Resource = "*"  # Se puede limitar a un bus específico
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eventbridge_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.eventbridge.arn
}

# Política para SES
resource "aws_iam_policy" "ses" {
  name = "${var.project_name}-${var.environment}-ses-send"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "ses:SendEmail"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ses_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.ses.arn
}