# ============================================================
# COOKIE WEBSITE SCANNING
# ============================================================

resource "aws_cloudwatch_event_rule" "cookie_scan" {
  name = "${var.project_name}-${var.environment}-scan"

  description = "Recurring Cookie Management website scan"

  schedule_expression = var.scan_schedule
}


# Connect scan schedule to scan Lambda
resource "aws_cloudwatch_event_target" "cookie_scan" {
  rule = aws_cloudwatch_event_rule.cookie_scan.name

  arn = aws_lambda_function.scan.arn
}


# Allow EventBridge to invoke scan Lambda
resource "aws_lambda_permission" "allow_scan_eventbridge" {
  statement_id = "AllowEventBridgeScan"

  action = "lambda:InvokeFunction"

  function_name = aws_lambda_function.scan.function_name

  principal = "events.amazonaws.com"

  source_arn = aws_cloudwatch_event_rule.cookie_scan.arn
}


# ============================================================
# RECURRING COOKIE SCRIPT PUBLISHING
# ============================================================

# 1. Create the recurring publishing schedule
resource "aws_cloudwatch_event_rule" "cookie_publish" {
  name = "${var.project_name}-${var.environment}-publish"

  description = "Recurring Cookie Management script publishing"

  schedule_expression = var.publish_schedule
}


# 2. Connect publishing schedule to publishing Lambda
resource "aws_cloudwatch_event_target" "cookie_publish" {
  rule = aws_cloudwatch_event_rule.cookie_publish.name

  arn = aws_lambda_function.publish.arn
}


# 3. Allow EventBridge to invoke publishing Lambda
resource "aws_lambda_permission" "allow_publish_eventbridge" {
  statement_id = "AllowEventBridgePublish"

  action = "lambda:InvokeFunction"

  function_name = aws_lambda_function.publish.function_name

  principal = "events.amazonaws.com"

  source_arn = aws_cloudwatch_event_rule.cookie_publish.arn
}