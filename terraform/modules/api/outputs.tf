output "api_url" {
  description = "API Gateway URL"
  value       = "${aws_api_gateway_deployment.api.invoke_url}${var.environment}"
}

output "lambda_function_name" {
  description = "Lambda関数名"
  value       = aws_lambda_function.api.function_name
}

output "api_gateway_id" {
  description = "API Gateway ID"
  value       = aws_api_gateway_rest_api.api.id
}

output "custom_domain_url" {
  description = "カスタムドメインURL"
  value       = var.api_domain_name != "" ? "https://${var.api_domain_name}" : ""
}