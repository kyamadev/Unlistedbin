variable "environment" {
  description = "環境（dev, staging, prod）"
}

variable "project_name" {
  description = "プロジェクト名"
}

variable "lambda_name" {
  description = "Lambda関数名"
}

variable "lambda_handler" {
  description = "Lambda関数のハンドラー"
}

variable "runtime" {
  description = "Lambda関数のランタイム"
}

variable "cognito_user_pool" {
  description = "Cognito User Pool ARN"
}

variable "cognito_client_id" {
  description = "Cognito App Client ID"
}

variable "api_domain_name" {
  description = "API Gateway カスタムドメイン名"
  default     = ""
}

variable "certificate_arn" {
  description = "SSL証明書ARN"
  default     = ""
}

variable "vpc_id" {
  description = "VPC ID"
}

variable "subnet_ids" {
  description = "サブネットIDのリスト"
  type        = list(string)
}

variable "security_groups" {
  description = "セキュリティグループIDのリスト"
  type        = list(string)
}

variable "db_endpoint" {
  description = "データベースエンドポイント"
}

variable "db_name" {
  description = "データベース名"
}

variable "db_username" {
  description = "データベースユーザー名"
  sensitive   = true
}

variable "db_password" {
  description = "データベースパスワード"
  sensitive   = true
}

variable "r2_bucket" {
  description = "Cloudflare R2 バケット名"
}

variable "r2_access_key" {
  description = "Cloudflare R2 アクセスキー"
  sensitive   = true
}

variable "r2_secret_key" {
  description = "Cloudflare R2 シークレットキー"
  sensitive   = true
}

variable "r2_endpoint" {
  description = "Cloudflare R2 エンドポイント"
}

variable "aws_region" {
  description = "AWS リージョン"
  default     = "ap-northeast-1"
}

variable "frontend_url" {
  description = "フロントエンドの URL"
  default     = "https://unlistedbin.com"
}

variable "cookie_domain" {
  description = "Cookie ドメイン"
  default     = "unlistedbin.com"
}