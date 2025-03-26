variable "environment" {
  description = "環境（dev, staging, prod）"
}

variable "project_name" {
  description = "プロジェクト名"
}

variable "db_name" {
  description = "データベース名"
}

variable "db_username" {
  description = "データベースのユーザー名"
  sensitive   = true
}

variable "db_password" {
  description = "データベースのパスワード"
  sensitive   = true
}

variable "instance_class" {
  description = "RDSインスタンスクラス"
  default     = "db.t3.micro" # 小規模構成の場合
}

variable "allocated_storage" {
  description = "割り当てるストレージサイズ（GB）"
  default     = 20
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