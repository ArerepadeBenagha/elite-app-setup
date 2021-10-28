resource "aws_wafv2_rule_group" "example" {
  capacity = 10
  name     = "example-rule-group"
  scope    = "REGIONAL"

  rule {
    name     = "rule-to-exclude-a"
    priority = 1

    action {
      block {}
    }

    statement {
      geo_match_statement {
        country_codes = ["US"]
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "friendly-rule-metric-name"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "friendly-metric-name"
    sampled_requests_enabled   = true
  }
}

resource "aws_wafv2_web_acl" "test" {
  name  = "rule-group-example"
  scope = "REGIONAL"

  default_action {
    block {}
  }

  rule {
    name     = "rule-1"
    priority = 2

    override_action {
      count {}
    }

    statement {
      rule_group_reference_statement {
        arn = aws_wafv2_rule_group.example.arn

        excluded_rule {
          name = "rule-to-exclude-a"
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "friendly-rule-metric-name"
      sampled_requests_enabled   = true
    }
  }

  tags = merge(local.common_tags,
    { Name = "nginxwaf"
  Security = "waf-devpublic" })

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "friendly-metric-name"
    sampled_requests_enabled   = true
  }
}
///////
resource "aws_s3_bucket" "bucket" {
  bucket = "aws-waf-logs-test1xaz"
  acl    = "private"
}

resource "aws_iam_role" "firehose_role" {
  name = join("-", [local.application.app_name, "firehose_test_role"])

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "firehose.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}
resource "aws_kinesis_firehose_delivery_stream" "test_stream" {
  name        = "aws-waf-logs-test-stream"
  destination = "s3"

  s3_configuration {
    role_arn   = aws_iam_role.firehose_role.arn
    bucket_arn = aws_s3_bucket.bucket.arn
  }
}

# ///////////////
resource "aws_wafv2_web_acl_logging_configuration" "example" {
  log_destination_configs = [aws_kinesis_firehose_delivery_stream.test_stream.arn]
  resource_arn            = aws_wafv2_web_acl.test.arn
}