resource "aws_wafv2_web_acl" "this" {
  name        = var.name
  description = "WAF for ${var.name} - CloudFront distribution and contact API"
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  # AWS managed common rule set: broad protection against OWASP-style attacks.
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.name}-common"
      sampled_requests_enabled   = true
    }
  }

  # Known Bad Inputs includes the Log4JRCE rule (satisfies CKV2_AWS_47).
  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.name}-known-bad-inputs"
      sampled_requests_enabled   = true
    }
  }

  # Rate-based rule: block IPs exceeding the request threshold in 5 minutes.
  rule {
    name     = "RateLimit"
    priority = 3

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = var.rate_limit
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.name}-rate-limit"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = var.name
    sampled_requests_enabled   = true
  }

  tags = {
    Name = var.name
  }
}

# WAF logging. The destination CloudWatch log group name MUST start with
# "aws-waf-logs-". For a CLOUDFRONT-scoped Web ACL the log group must be in
# us-east-1 (the region this stack runs in). Enabled when logging_enabled.
resource "aws_cloudwatch_log_group" "waf" {
  count = var.logging_enabled ? 1 : 0

  name              = "aws-waf-logs-${var.name}"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "aws-waf-logs-${var.name}"
  }
}

resource "aws_wafv2_web_acl_logging_configuration" "this" {
  count = var.logging_enabled ? 1 : 0

  resource_arn            = aws_wafv2_web_acl.this.arn
  log_destination_configs = [aws_cloudwatch_log_group.waf[0].arn]
}
