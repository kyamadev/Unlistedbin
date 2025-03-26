output "db_endpoint" {
  description = "RDSインスタンスのエンドポイント"
  value       = aws_db_instance.mysql.endpoint
}

output "db_name" {
  description = "データベース名"
  value       = aws_db_instance.mysql.db_name
}

output "db_instance_id" {
  description = "RDSインスタンスID"
  value       = aws_db_instance.mysql.id
}