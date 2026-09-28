output "scan_lambda_name" {
  value = aws_lambda_function.scan.function_name
}

output "publish_lambda_name" {
  value = aws_lambda_function.publish.function_name
}

output "cookie_api_secret_arn" {
  value = aws_secretsmanager_secret.cookie_api.arn
}

output "scan_schedule" {
  value = aws_cloudwatch_event_rule.cookie_scan.schedule_expression
}

output "publish_schedule" {
  value = aws_cloudwatch_event_rule.cookie_publish.schedule_expression
}