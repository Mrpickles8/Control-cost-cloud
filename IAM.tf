resource "aws_iam_role" "lambda_role" {
  name = "cost-calculator-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"

        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}


resource "aws_iam_role_policy" "lambda_policy" {
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "ce:GetCostAndUsage"
        ]

        Resource = [
          "*"
        ]
      },
      {
        Effect = "Allow"

        Action = [
          "s3:PutObject"
        ]

        Resource = [
          "${aws_s3_bucket.reports.arn}/*"
        ]
      },
      {
        Effect = "Allow"

        Action = [
          "logs:*"
        ]

        Resource = [
          "*"
        ]
      }
    ]
  })
}

