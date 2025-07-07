resource "aws_apigatewayv2_api" "goodbadchad-api" {
  name          = "goodbadchad-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = [
      "https://${var.game_domain_name}",
      "https://www.${var.game_domain_name}"
    ]
    allow_methods     = ["GET", "DELETE", "POST", "OPTIONS"]
    allow_headers     = ["Content-Type", "Authorization"]
    max_age           = 3600
    allow_credentials = true
  }
}

resource "aws_lambda_permission" "invoke_api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.backend.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.goodbadchad-api.execution_arn}/*/*"
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.goodbadchad-api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.backend.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "docs" {
  api_id    = aws_apigatewayv2_api.goodbadchad-api.id
  route_key = "GET /"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_route" "login" {
  api_id    = aws_apigatewayv2_api.goodbadchad-api.id
  route_key = "POST /player/login"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_route" "create_player" {
  api_id    = aws_apigatewayv2_api.goodbadchad-api.id
  route_key = "POST /player"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_route" "get_all_players" {
  api_id    = aws_apigatewayv2_api.goodbadchad-api.id
  route_key = "GET /player/all"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_route" "get_one_player" {
  api_id    = aws_apigatewayv2_api.goodbadchad-api.id
  route_key = "GET /player"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_route" "create_save" {
  api_id    = aws_apigatewayv2_api.goodbadchad-api.id
  route_key = "POST /save"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_route" "get_full_save" {
  api_id    = aws_apigatewayv2_api.goodbadchad-api.id
  route_key = "GET /save/{save_id}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_route" "delete_save" {
  api_id    = aws_apigatewayv2_api.goodbadchad-api.id
  route_key = "DELETE /save/{save_id}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_route" "get_player_saves" {
  api_id    = aws_apigatewayv2_api.goodbadchad-api.id
  route_key = "GET /save"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.goodbadchad-api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_apigatewayv2_domain_name" "api_root" {
  domain_name = var.api_domain_name

  domain_name_configuration {
    certificate_arn = aws_acm_certificate_validation.cert_validation.certificate_arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}

resource "aws_apigatewayv2_domain_name" "api_www" {
  domain_name = "www.${var.api_domain_name}"

  domain_name_configuration {
    certificate_arn = aws_acm_certificate_validation.cert_validation.certificate_arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}

resource "aws_apigatewayv2_api_mapping" "mapping" {
  api_id      = aws_apigatewayv2_api.goodbadchad-api.id
  domain_name = aws_apigatewayv2_domain_name.api_root.id
  stage       = aws_apigatewayv2_stage.default.name
}

resource "aws_apigatewayv2_api_mapping" "mapping_www" {
  api_id      = aws_apigatewayv2_api.goodbadchad-api.id
  domain_name = "www.${aws_apigatewayv2_domain_name.api_root.id}"
  stage       = aws_apigatewayv2_stage.default.name
}

resource "aws_route53_record" "api_root" {
  zone_id = var.route_53_hosted_zone_id
  name    = var.api_domain_name
  type    = "A"

  alias {
    name                   = aws_apigatewayv2_domain_name.api_root.domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.api_root.domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "api_www" {
  zone_id = var.route_53_hosted_zone_id
  name    = "www.${var.api_domain_name}"
  type    = "A"

  alias {
    name                   = aws_apigatewayv2_domain_name.api_www.domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.api_www.domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = false
  }
}

output "api_gateway_path" {
  value = aws_apigatewayv2_api.goodbadchad-api.api_endpoint
}
