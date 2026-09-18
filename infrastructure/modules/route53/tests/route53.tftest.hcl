mock_provider "aws" {
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "216066926519"
    }
  }
}

run "creates_public_hosted_zone" {
  command = plan

  variables {
    domain_name = "frankidugboe.com"
  }

  assert {
    condition     = aws_route53_zone.this.name == "frankidugboe.com"
    error_message = "The hosted zone must use frankidugboe.com."
  }

  assert {
    condition     = aws_route53_zone.this.force_destroy == false
    error_message = "The hosted zone must not allow forced destruction."
  }
}

run "enables_dnssec_signing" {
  command = plan

  variables {
    domain_name    = "frankidugboe.com"
    dnssec_enabled = true
  }

  assert {
    condition     = aws_kms_key.dnssec[0].customer_master_key_spec == "ECC_NIST_P256"
    error_message = "The DNSSEC key must be an ECC_NIST_P256 asymmetric key."
  }

  assert {
    condition     = aws_kms_key.dnssec[0].key_usage == "SIGN_VERIFY"
    error_message = "The DNSSEC key must be usable for signing."
  }

  assert {
    condition     = length(aws_route53_key_signing_key.this) == 1
    error_message = "A key-signing key must be created when DNSSEC is enabled."
  }

  assert {
    condition     = length(aws_route53_hosted_zone_dnssec.this) == 1
    error_message = "Zone signing must be enabled when DNSSEC is enabled."
  }
}
