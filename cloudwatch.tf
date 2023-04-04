
resource "aws_cloudwatch_log_subscription_filter" "cw-sf" {
  depends_on      = [aws_lambda_permission.allow_to_cloudwatch_call_secret_sns]
  name            = "describesecret"
  log_group_name  = aws_cloudwatch_log_group.secret-sns-logs.name
  filter_pattern  = "{ $.eventName = DescribeSecret }"
  destination_arn = aws_lambda_function.secret_lambda_function.arn
  distribution    = "ByLogStream"
}

/* resource "aws_cloudwatch_event_target" "sns_target" {
  rule      = aws_cloudwatch_event_rule.secrets_manager_access_rule.name
  arn       = aws_sns_topic.send-msg-topic.arn
  target_id = "send-msg"
} */

resource "aws_lambda_permission" "allow_to_cloudwatch_call_secret_sns" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.secret_lambda_function.function_name
  principal     = "logs.ap-south-1.amazonaws.com"
  /* source_arn    = aws_cloudwatch_event_rule.secrets_manager_access_rule.arn */
  source_arn = "${aws_cloudwatch_log_group.secret-sns-logs.arn}:*"

}
