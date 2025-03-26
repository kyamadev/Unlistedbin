output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "private_subnet_ids" {
  description = "プライベートサブネットのIDリスト"
  value       = aws_subnet.private.*.id
}

output "public_subnet_ids" {
  description = "パブリックサブネットのIDリスト"
  value       = aws_subnet.public.*.id
}

output "lambda_security_group_id" {
  description = "Lambda用セキュリティグループID"
  value       = aws_security_group.lambda.id
}

output "db_security_group_id" {
  description = "RDS用セキュリティグループID"
  value       = aws_security_group.db.id
}