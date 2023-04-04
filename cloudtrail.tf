data "aws_caller_identity" "current" {}

resource "aws_cloudtrail" "secret-sns" {
  name                          = "secret-sns-cloud-trail"
  s3_bucket_name                = aws_s3_bucket.secret-sns-bucket.id
  s3_key_prefix                 = "prefix"
  enable_logging                = true
  include_global_service_events = true

  /* event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3"]
    }
  } */

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::Lambda::Function"
      values = ["arn:aws:lambda"]
    }
  }

  # sendint events to Cloudwatch logs group 
  cloud_watch_logs_role_arn  = aws_iam_role.cloudtrail_cloudwatch_role.arn
  cloud_watch_logs_group_arn =  "${aws_cloudwatch_log_group.secret-sns-logs.arn}:*"



  # Advance Event Selector for Secret Manager
  /* advanced_event_selector {
    name = "Log Describe Secret events"


    field_selector {
      field  = "eventCategory"
      equals = ["Data"]
    }

    field_selector {
      field  = "resources.type"
      equals = ["${aws_cloudtrail.secret-sns.arn}/*"]
    }

    field_selector {
      field  = "eventName"
      equals = ["DescribeSecrets"]
    }

    field_selector {
      field  = "readOnly"
      equals = ["false"]
    }


  } */

}

resource "aws_s3_bucket" "secret-sns-bucket" {
  bucket        = "secret-sns-tf-bucket"
  force_destroy = true

}

resource "aws_iam_role" "cloudtrail_cloudwatch_role" {
  name = "cloudtrail_cloudwatch_role"

  assume_role_policy = jsonencode(
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudtrail.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
})


depends_on = [
  aws_cloudwatch_log_group.secret-sns-logs,
]
}

data "aws_iam_policy_document" "s3_bucket_policy" {

  version = "2012-10-17"

  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.secret-sns-bucket.arn]
  }

  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.secret-sns-bucket.arn}/prefix/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }

}
/* 
data "aws_iam_policy_document" "cloudwatch_policy" {
   version = "2012-10-17"
   statement {
    sid = "AWSCloudTrailCreateLogStream"
    actions = ["logs:CreateLogStream"]
    resources = ["arn:aws:logs:*"]
  }

  statement {
    sid = "AWSCloudTrailPutLogEvents"
    actions = [ "logs:PutLogEvents" ]
    resources = ["arn:aws:logs:*"]
  }
  
} */

resource "aws_s3_bucket_policy" "secret-sns-attach-policy" {
  bucket = aws_s3_bucket.secret-sns-bucket.id
  policy = data.aws_iam_policy_document.s3_bucket_policy.json
}

resource "aws_cloudwatch_log_group" "secret-sns-logs" {
  name = "lambda/secret_lambda_function"

}

resource "aws_cloudwatch_log_stream" "secret-sns-stream" {
  name           = "secret-sns-log-stream"
  log_group_name = aws_cloudwatch_log_group.secret-sns-logs.name
}


resource "aws_iam_policy" "cloudtrail_cwl_logs_policy" {
  name        = "CloudTrail_CWL_Logs_Policy"
  path        = "/"
  description = "Allows CloudTrail to write logs to the specified CloudWatch Logs log group"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:*"
        ]
        Resource = ["${aws_cloudwatch_log_group.secret-sns-logs.arn}:*"]
      }
    ]
  })
}

/* resource "aws_iam_role_policy_attachment" "cloudtrail_cwl_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCloudTrailServicePolicy"
  role       = aws_iam_role.cloudtrail_cloudwatch_role.name
} */

resource "aws_iam_role_policy_attachment" "cloudtrail_cwl_logs_policy_attachment" {
  policy_arn = aws_iam_policy.cloudtrail_cwl_logs_policy.arn
  role       = aws_iam_role.cloudtrail_cloudwatch_role.name
}


/* resource "aws_iam_role" "iam_role_cloudwatch" {
  name = "aws-cloudwatch-role-cloudwatch"
  assume_role_policy = data.aws_iam_policy_document.cloudtrail_assume_role_policy.json
  
}

data "aws_iam_policy_document" "cloudtrail_assume_role_policy" {
  statement {
    sid     = "CloudtrailToCloudWatch"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }
} */

/* resource "aws_cloudwatch_log_resource_policy" "cloudtrail-cloudwatch-logs" {
  policy_name = "cloudtrail-cloudwatch-secret-logs"
  policy_document = data.aws_iam_policy_document.cloudwatch_policy.json
} */

