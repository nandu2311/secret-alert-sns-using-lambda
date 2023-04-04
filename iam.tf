## IAM Role and Policy ###
## Allows Lambda Function to Describe, stop and start EC2 Instances

resource "aws_iam_role" "secret_iam_role" {
  name               = "secret_iam_role"
  assume_role_policy = <<EOF
    {
        "Version": "2012-10-17",
        "Statement": [
            {
            "Action": "sts:AssumeRole",
            "Principal": {
                "Service": "lambda.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
            }
        ]
    }
EOF  

  /* depends_on = [
      aws_cloudwatch_log_group.secret-sns-logs
    ] */
}


data "aws_iam_policy_document" "secret_iam_policy" {

  statement {

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "arn:aws:logs:*:*:*",
    ]
  }

  statement {

    actions = [
      "secretsmanager:GetSecretValue"
    ]

    resources = [
      "arn:aws:secretsmanager:*:*:*",
    ]
  }

  statement {

    actions = [
      "sns:Publish"
    ]

    resources = [
      "arn:aws:sns:*:*:*",
    ]
  }

  statement {

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]
    resources = ["arn:aws:kms:*:*:*", ]
  }

  statement {
    actions = [
      "kms:RevokeGrant",
      "kms:CreateGrant",
      "kms:ListGrants"
    ]
    resources = ["*", ]
    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values   = [true]
    }
  }

}

resource "aws_iam_policy" "secret_sns_policy" {
  name   = "secret_access_policy"
  path   = "/"
  policy = data.aws_iam_policy_document.secret_iam_policy.json

}

resource "aws_iam_policy_attachment" "secret_access_policy" {
  name       = "iam_policy_attachment"
  roles      = [aws_iam_role.secret_iam_role.name]
  policy_arn = aws_iam_policy.secret_sns_policy.arn

}
