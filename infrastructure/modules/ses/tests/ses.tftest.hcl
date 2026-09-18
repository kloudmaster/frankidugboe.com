mock_provider "aws" {}

run "verifies_domain_identity_and_mail_from" {
  command = plan

  variables {
    domain_name     = "frankidugboe.com"
    route53_zone_id = "ZTEST123456789"
    aws_region      = "us-east-1"
  }

  assert {
    condition     = aws_sesv2_email_identity.domain.email_identity == "frankidugboe.com"
    error_message = "The SES identity must be the portfolio domain."
  }

  assert {
    condition     = aws_sesv2_email_identity_mail_from_attributes.domain.mail_from_domain == "mail.frankidugboe.com"
    error_message = "The custom MAIL FROM domain must be mail.<domain>."
  }

  assert {
    condition     = aws_route53_record.mail_from_mx.type == "MX"
    error_message = "A MAIL FROM MX record must be published."
  }

  assert {
    condition     = contains(aws_route53_record.mail_from_spf.records, "v=spf1 include:amazonses.com -all")
    error_message = "A MAIL FROM SPF TXT record must be published."
  }
}
