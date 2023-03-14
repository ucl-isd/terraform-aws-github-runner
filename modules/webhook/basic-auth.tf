# =======================================================================================
# Add authentication to the api gateway
# =======================================================================================

resource "aws_lambda_function" "github_auth" {
  function_name = "${var.prefix}-github-auth"
  package_type = "Image"
  image_uri = "413210965747.dkr.ecr.eu-west-2.amazonaws.com/devops/github-auth:1.1.7"
  role = aws_iam_role.github_auth.arn
  timeout = 300
  environment {
    variables = {
      API_GATEWAY_LOGIN = var.api_gateway_login
      API_GATEWAY_PASSWORD = var.api_gateway_password
    }
  }
}

resource "aws_cloudwatch_log_group" "github_auth_lambda" {
  name = "/aws/lambda/${var.prefix}-github-auth"
  retention_in_days = 30
}

resource "aws_iam_role" "github_auth" {
  name = "${var.prefix}-github-auth-lambda"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "github_auth" {
  role       = aws_iam_role.github_auth.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_apigatewayv2_authorizer" "github_auth" {
  api_id                            = aws_apigatewayv2_api.webhook.api_id
  authorizer_type                   = "REQUEST"
  authorizer_uri                    = aws_lambda_function.github_auth.invoke_arn
  identity_sources                  = ["$request.header.Authorization"]
  name                              = "${var.prefix}-github-auth"
  authorizer_payload_format_version = "2.0"
}

resource "aws_lambda_permission" "github_auth" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.github_auth.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.webhook.execution_arn}/*/*"
}
