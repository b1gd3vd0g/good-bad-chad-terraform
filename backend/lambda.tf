resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "logs" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "backend" {
  function_name = "gbc-saving-api"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "src/serverless.handler"
  runtime       = "nodejs22.x"

  filename = "gbc_save.zip"

  environment {
    variables = {
      DBNAME = var.db_name
      PGHOST = aws_db_instance.postgres.address
      PGPASS = var.pg_password
      PGPORT = 5432
      PGUSER = var.pg_username
      JWTSEC = var.jwt_secret
    }
  }
}
