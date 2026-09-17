mock_provider "aws" {
  mock_resource "aws_acm_certificate" {
    defaults = {
      arn = "arn:aws:acm:us-east-1:123456789012:certificate/test-certificate"

      domain_validation_options = [
        {
          domain_name           = "frankidugboe.com"
          resource_record_name  = "_test.frankidugboe.com."
          resource_record_type  = "CNAME"
          resource_record_value = "_validation.acm-validations.aws."
        },
        {
          domain_name           = "www.frankidugboe.com"
          resource_record_name  = "_test.www.frankidugboe.com."
          resource_record_type  = "CNAME"
          resource_record_value = "_validation-www.acm-validations.aws."
        },
      ]
    }
  }
}

run "configures_public_dns_validated_certificate" {
  command = plan

  variables {
    domain_name               = "frankidugboe.com"
    subject_alternative_names = ["www.frankidugboe.com"]
    route53_zone_id           = "ZTEST123456789"
  }

  assert {
    condition     = aws_acm_certificate.this.domain_name == "frankidugboe.com"
    error_message = "The primary ACM certificate name must be frankidugboe.com."
  }

  assert {
    condition     = aws_acm_certificate.this.validation_method == "DNS"
    error_message = "The ACM certificate must use DNS validation."
  }

  assert {
    condition = contains(
      aws_acm_certificate.this.subject_alternative_names,
      "www.frankidugboe.com",
    )
    error_message = "The certificate must include www.frankidugboe.com as a SAN."
  }
}

run "creates_dns_validation_resources" {
  command = apply

  variables {
    domain_name               = "frankidugboe.com"
    subject_alternative_names = ["www.frankidugboe.com"]
    route53_zone_id           = "ZTEST123456789"
  }

  assert {
    condition     = length(aws_route53_record.validation) == 2
    error_message = "DNS validation records must be created for both certificate names."
  }

  assert {
    condition     = aws_acm_certificate_validation.this.certificate_arn == aws_acm_certificate.this.arn
    error_message = "The validation resource must validate the ACM certificate."
  }
}
