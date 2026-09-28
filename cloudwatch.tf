resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role = aws_iam_role.cookie_lambda.name

  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}




resource "aws_cloudwatch_log_group" "scan" {
  name = "/aws/lambda/${aws_lambda_function.scan.function_name}"

  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "publish" {
  name = "/aws/lambda/${aws_lambda_function.publish.function_name}"

  retention_in_days = 30
}