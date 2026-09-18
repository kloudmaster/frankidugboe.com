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

# DNSSEC signing. Route 53 DNSSEC requires an asymmetric KMS key
# (ECC_NIST_P256, SIGN_VERIFY) in us-east-1 whose key policy allows the
# Route 53 DNSSEC service to use and manage the grant. Enabled when
# dnssec_enabled is true. After apply, the DS record must be published at the
# domain registrar to complete the chain of trust (see the ds_record output).
data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "dnssec_key" {
  count = var.dnssec_enabled ? 1 : 0

  # checkov:skip=CKV_AWS_109:Root account key-policy statement is the AWS-required KMS default (prevents key lockout).
  # checkov:skip=CKV_AWS_111:Same root key-policy statement; scoping it would risk losing control of the key.
  # checkov:skip=CKV_AWS_356:KMS key policies are attached to a single key; "*" resource refers to that key only.

  statement {
    sid    = "EnableIAMUserPermissions"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "AllowRoute53DNSSECService"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["dnssec-route53.amazonaws.com"]
    }

    actions = [
      "kms:DescribeKey",
      "kms:GetPublicKey",
      "kms:Sign",
    ]

    resources = ["*"]
  }

  statement {
    sid    = "AllowRoute53DNSSECGrant"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["dnssec-route53.amazonaws.com"]
    }

    actions   = ["kms:CreateGrant"]
    resources = ["*"]

    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values   = ["true"]
    }
  }
}

resource "aws_kms_key" "dnssec" {
  count = var.dnssec_enabled ? 1 : 0

  description              = "DNSSEC signing key for ${var.domain_name}"
  customer_master_key_spec = "ECC_NIST_P256"
  key_usage                = "SIGN_VERIFY"
  deletion_window_in_days  = 7
  policy                   = data.aws_iam_policy_document.dnssec_key[0].json

  tags = {
    Name = "${var.domain_name}-dnssec"
  }
}

resource "aws_kms_alias" "dnssec" {
  count = var.dnssec_enabled ? 1 : 0

  name          = "alias/${replace(var.domain_name, ".", "-")}-dnssec"
  target_key_id = aws_kms_key.dnssec[0].key_id
}

resource "aws_route53_key_signing_key" "this" {
  count = var.dnssec_enabled ? 1 : 0

  hosted_zone_id             = aws_route53_zone.this.zone_id
  key_management_service_arn = aws_kms_key.dnssec[0].arn
  name                       = "${replace(var.domain_name, ".", "-")}-ksk"
}

resource "aws_route53_hosted_zone_dnssec" "this" {
  count = var.dnssec_enabled ? 1 : 0

  hosted_zone_id = aws_route53_key_signing_key.this[0].hosted_zone_id

  depends_on = [aws_route53_key_signing_key.this]
}
