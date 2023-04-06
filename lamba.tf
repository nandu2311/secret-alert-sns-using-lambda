## AWS Lambda Function ##
## AWS Lambda API Requires a ZIP Files with the execution code
data "archive_file" "secret_lambda" {
  type        = "zip"
  source_file = "secret-funtion.py"
  output_path = "secret-lambda.zip"

}

### Lambda defined that runs the Python Code with the specified IAM Role
resource "aws_lambda_function" "secret_lambda_function" {
  filename         = data.archive_file.secret_lambda.output_path
  function_name    = "secret_lambda_function"
  role             = aws_iam_role.secret_iam_role.arn
  handler          = "secret-funtion.lambda_handler"
  runtime          = "python3.9"
  timeout          = 300
  source_code_hash = data.archive_file.secret_lambda.output_base64sha256

  depends_on = [
    aws_iam_policy_attachment.secret_access_policy,
    aws_cloudwatch_log_group.secret-sns-logs,
  ]

  environment {
    variables = {
      secretsnstopic = aws_sns_topic.send-msg-topic.arn
    }
  }
}

