terraform {
  required_version = "1.16.5"
  cloud {
    organization = "dominionorg"

    workspaces {
      name = "terraform-aws-wrk02"
    }
  }
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Provider par default 
provider "aws" {
  region = "eu-west-1"
}

# Provider spécifique au Billing
provider "aws" {
  alias  = "us_east"
  region = "us-east-1"
}

resource "aws_sns_topic" "cost_alerts" {
  provider = aws.us_east
  name     = "cost-calculator-cost-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  provider  = aws.us_east
  topic_arn = aws_sns_topic.cost_alerts.arn
  protocol  = "email"
  endpoint  = "davidartaud1@gmail.com"
}


resource "aws_cloudwatch_metric_alarm" "billing_alarm" {
  provider            = aws.us_east
  alarm_name          = "cost-calculator-billing-alert"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = 86400 #24 heures
  statistic           = "Maximum"
  threshold           = var.alert_threshold_eur
  alarm_description   = "Alert if the charges exceeds 100 eur"
  actions_enabled     = true
  alarm_actions       = [aws_sns_topic.cost_alerts.arn]
  dimensions = {
    Currency = "EUR"
  }
}

resource "aws_cloudwatch_dashboard" "cost" {
  dashboard_name = "cost-calculator-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          title  = "AWS monthly estimated cost (eur)"
          region = "us-east-1"
          metrics = [
            [
              "AWS/Billing",
              "EstimatedCharges",
              "Currency",
              "EUR"
            ]
          ]
          period = 86400
          stat   = "Maximum"
        }
      },
      {
        type   = "text"
        x      = 0
        y      = 7
        width  = 3
        height = 3

        properties = {
          markdown = "Hello world"
        }
      }
    ]
  })
}

resource "aws_s3_bucket" "reports" {
  bucket = "cost-calculator-reports-${random_id.suffix.hex}"
}

resource "random_id" "suffix" { byte_length = 4 }

resource "aws_s3_bucket_public_access_block" "reports" {
  bucket                  = aws_s3_bucket.reports.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "reports" {
  bucket = aws_s3_bucket.reports.id
  versioning_configuration {
    status = "Enabled"
  }
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "lambda_report.py"
  output_path = "lambda_report.zip"
}


resource "aws_lambda_function" "weekly_reports" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "cost-calculator-weekly-report"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_report.lambda_handler"
  runtime          = "python3.12"
  timeout          = 60
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  environment {
    variables = { REPORT_BUCKET = aws_s3_bucket.reports.bucket }
  }
}

resource "aws_cloudwatch_event_rule" "weekly" {
  name                = "cost-calculator-weekly-trigger"
  schedule_expression = "cron(0 8 ? * MON *)"
  force_destroy       = true
}

resource "aws_cloudwatch_event_target" "weekly" {
  rule = aws_cloudwatch_event_rule.weekly.name
  arn  = aws_lambda_function.weekly_reports.arn
}

resource "aws_lambda_permission" "eventbridge" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.weekly_reports.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.weekly.arn
}