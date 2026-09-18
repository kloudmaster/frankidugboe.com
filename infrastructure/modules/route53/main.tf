resource "aws_route53_zone" "this" {
  name          = var.domain_name
  force_destroy = false

  tags = {
    Name        = var.domain_name
    Project     = "frankidugboe.com"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

# DNS query logging. Route 53 query logging requires the CloudWatch log group
# to live in us-east-1 and a resource policy permitting the Route 53 service
# to write to it. Enabled when query_logging_enabled is true.
resource "aws_cloudwatch_log_group" "query_log" {
  count = var.query_logging_enabled ? 1 : 0

  name              = "/aws/route53/${var.domain_name}"
  retention_in_days = var.query_log_retention_days

  tags = {
    Name = "/aws/route53/${var.domain_name}"
  }
}

data "aws_iam_policy_document" "query_log" {
  count = var.query_logging_enabled ? 1 : 0

  statement {
    sid    = "Route53QueryLogging"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["route53.amazonaws.com"]
    }

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["${aws_cloudwatch_log_group.query_log[0].arn}:*"]
  }
}

resource "aws_cloudwatch_log_resource_policy" "query_log" {
  count = var.query_logging_enabled ? 1 : 0

  policy_name     = "${replace(var.domain_name, ".", "-")}-route53-query-logging"
  policy_document = data.aws_iam_policy_document.query_log[0].json
}

resource "aws_route53_query_log" "this" {
  count = var.query_logging_enabled ? 1 : 0

  zone_id                  = aws_route53_zone.this.zone_id
  cloudwatch_log_group_arn = aws_cloudwatch_log_group.query_log[0].arn

  depends_on = [aws_cloudwatch_log_resource_policy.query_log]
}
