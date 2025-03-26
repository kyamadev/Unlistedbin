variable "project_name" {
  description = "プロジェクト名"
  default     = "unlistedbin"
}

variable "environment" {
  description = "環境（dev, staging, prod）"
  default     = "dev"
}

variable "aws_region" {
  description = "AWS リージョン"
  default     = "ap-northeast-1" # 東京リージョン
}

variable "vpc_cidr" {
  description = "VPC CIDR ブロック"
  default     = "10.0.0.0/16"
}

variable "db_name" {
  description = "データベース名"
  default     = "unlistedbindb"
}

variable "db_username" {
  description = "データベースのユーザー名"
  sensitive   = true
}

variable "db_password" {
  description = "データベースのパスワード"
  sensitive   = true
}

variable "api_domain_name" {
  description = "API のドメイン名"
  default     = "api.unlistedbin.com"
}

variable "ses_sender_email" {
  description = "SESで使用する送信元メールアドレス"
  default     = "noreply@unlistedbin.com"
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