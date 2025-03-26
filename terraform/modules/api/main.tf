# Lambda用IAMロール
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-lambda-role-${var.environment}"
  
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
  
  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Lambda実行用ポリシー
resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.project_name}-lambda-policy-${var.environment}"
  role = aws_iam_role.lambda_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "cognito-idp:AdminInitiateAuth",
          "cognito-idp:AdminConfirmSignUp",
          "cognito-idp:AdminGetUser",
          "cognito-idp:AdminUpdateUserAttributes",
          "cognito-idp:AdminDeleteUser",
          "cognito-idp:AdminResetUserPassword",
          "cognito-idp:AdminConfirmForgotPassword"
        ]
        Effect   = "Allow"
        Resource = var.cognito_user_pool
      }
    ]
  })
}

# CloudWatch Logsへのアクセス権限
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Lambda関数
resource "aws_lambda_function" "api" {
  function_name = var.lambda_name
  description   = "Unlistedbin API backend - ${var.environment}"
  role          = aws_iam_role.lambda_role.arn
  handler       = var.lambda_handler
  runtime       = var.runtime
  timeout       = 30
  memory_size   = 256
  
  # デプロイパッケージ（CI/CDで更新する）
  filename      = "dummy.zip"
  
  # ソースコードのハッシュ変更時のみ更新を許可
  source_code_hash = filebase64sha256("dummy.zip")
  
  # VPC設定
  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = var.security_groups
  }
  
  # 環境変数
  environment {
    variables = {
      ENV                  = var.environment
      MYSQL_DSN            = "mysql://${var.db_username}:${var.db_password}@tcp(${var.db_endpoint})/${var.db_name}?parseTime=true"
      COGNITO_REGION       = var.aws_region
      COGNITO_USER_POOL_ID = element(split("/", var.cognito_user_pool), 1)
      COGNITO_CLIENT_ID    = var.cognito_client_id
      R2_BUCKET            = var.r2_bucket
      R2_ACCESS_KEY_ID     = var.r2_access_key
      R2_SECRET_ACCESS_KEY = var.r2_secret_key
      R2_ENDPOINT          = var.r2_endpoint
      FRONTEND_URL         = var.frontend_url
      COOKIE_DOMAIN        = var.cookie_domain
    }
  }
  
  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
  
  # Lambda関数が作成された後に上書きされることを許可
  lifecycle {
    ignore_changes = [
      filename,
      source_code_hash,
    ]
  }
}

# API Gateway REST API
resource "aws_api_gateway_rest_api" "api" {
  name        = "${var.project_name}-api-${var.environment}"
  description = "Unlistedbin API Gateway - ${var.environment}"
  
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  
  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# API Gateway Proxyリソース
resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "{proxy+}"
}

# API Gateway ANY メソッド
resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization_type = "NONE"
}

# API Gateway Lambda統合
resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy.http_method
  
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.api.invoke_arn
}

# API Gateway ルートパスANYメソッド
resource "aws_api_gateway_method" "proxy_root" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_rest_api.api.root_resource_id
  http_method   = "ANY"
  authorization_type = "NONE"
}

# API Gateway ルートパスLambda統合
resource "aws_api_gateway_integration" "lambda_root" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_rest_api.api.root_resource_id
  http_method = aws_api_gateway_method.proxy_root.http_method
  
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.api.invoke_arn
}

# API Gatewayデプロイメント
resource "aws_api_gateway_deployment" "api" {
  depends_on = [
    aws_api_gateway_integration.lambda,
    aws_api_gateway_integration.lambda_root,
  ]
  
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = var.environment
  
  lifecycle {
    create_before_destroy = true
  }
}

# API Gatewayステージ設定
resource "aws_api_gateway_stage" "api" {
  deployment_id = aws_api_gateway_deployment.api.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = var.environment
  
  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# API Gateway LambdaのPermission設定
resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api.function_name
  principal     = "apigateway.amazonaws.com"
  
  # API Gatewayからの呼び出しのみを許可
  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

# カスタムドメイン設定（オプション）
resource "aws_api_gateway_domain_name" "api" {
  count           = var.api_domain_name != "" ? 1 : 0
  domain_name     = var.api_domain_name
  certificate_arn = var.certificate_arn
  
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  
  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# API Gateway ベースパスマッピング（オプション）
resource "aws_api_gateway_base_path_mapping" "api" {
  count       = var.api_domain_name != "" ? 1 : 0
  api_id      = aws_api_gateway_rest_api.api.id
  stage_name  = aws_api_gateway_stage.api.stage_name
  domain_name = aws_api_gateway_domain_name.api[0].domain_name
}