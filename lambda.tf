data "archive_file" "scan_lambda" {
  type        = "zip"
  source_file = "${path.module}/lambda/scan.py"
  output_path = "${path.module}/scan.zip"
}

data "archive_file" "publish_lambda" {
  type        = "zip"
  source_file = "${path.module}/lambda/publish.py"
  output_path = "${path.module}/publish.zip"
}

resource "aws_lambda_function" "scan" {
  function_name    = "${var.project_name}-${var.environment}-scan"
  role             = aws_iam_role.cookie_lambda.arn
  handler          = "scan.lambda_handler"
  runtime          = "python3.12"
  filename         = data.archive_file.scan_lambda.output_path
  source_code_hash = data.archive_file.scan_lambda.output_base64sha256

  environment {
    variables = {
      COOKIE_API_URL    = var.cookie_api_url
      SECRET_ARN        = aws_secretsmanager_secret.cookie_api.arn
      APPLICATIONS_JSON = jsonencode(var.applications)
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic,
    aws_iam_role_policy.lambda_secret_access
  ]
}

resource "aws_lambda_function" "publish" {
  function_name    = "${var.project_name}-${var.environment}-publish"
  role             = aws_iam_role.cookie_lambda.arn
  handler          = "publish.lambda_handler"
  runtime          = "python3.12"
  filename         = data.archive_file.publish_lambda.output_path
  source_code_hash = data.archive_file.publish_lambda.output_base64sha256

  environment {
    variables = {
      COOKIE_API_URL    = var.cookie_api_url
      SECRET_ARN        = aws_secretsmanager_secret.cookie_api.arn
      APPLICATIONS_JSON = jsonencode(var.applications)
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic,
    aws_iam_role_policy.lambda_secret_access
  ]
}


