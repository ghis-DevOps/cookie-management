resource "aws_secretsmanager_secret" "cookie_api" {
  name = var.cookie_api_secret_name

  description = "Cookie Management platform API credentials"

  recovery_window_in_days = 7
}