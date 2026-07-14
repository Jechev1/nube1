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

# Politica para DynamoDB (todas las tablas base, en un solo policy attachment).
# NOTA: AWS permite max 10 managed policies por rol. Al usar un rol
# compartido para todas las Lambdas, cada modulo (auth, catalog, orders...)
# suma sus propias policies a ese mismo limite. Este policy unico (en vez de
# uno por tabla) deja mas margen, pero sigue sin ser minimo privilegio real:
# la forma correcta es un rol por Lambda, scoped a lo que esa Lambda usa.
locals {
  tables = ["Products", "Stores", "Orders", "Cart", "Users"]
}

resource "aws_iam_policy" "dynamodb" {
  name = "${var.project_name}-${var.environment}-dynamodb-base-tables"
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
        Resource = flatten([
          for t in local.tables : [
            "arn:aws:dynamodb:${var.aws_region}:${var.account_id}:table/${t}",
            "arn:aws:dynamodb:${var.aws_region}:${var.account_id}:table/${t}/index/*"
          ]
        ])
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "dynamodb_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.dynamodb.arn
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