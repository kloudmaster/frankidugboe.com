mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "216066926519"
    }
  }

  mock_resource "aws_route53_zone" {
    defaults = {
      zone_id = "Z05203182KTV9HKTZIEXD"

      name_servers = [
        "ns-1472.awsdns-56.org",
        "ns-1820.awsdns-35.co.uk",
        "ns-243.awsdns-30.com",
        "ns-658.awsdns-18.net",
      ]
    }
  }

  mock_resource "aws_acm_certificate" {
    defaults = {
      arn = "arn:aws:acm:us-east-1:216066926519:certificate/test-certificate"

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

  mock_resource "aws_cloudfront_function" {
    defaults = {
      arn = "arn:aws:cloudfront::216066926519:function/frankidugboe-com-viewer-request"
    }
  }

  mock_resource "aws_cloudfront_distribution" {
    defaults = {
      arn            = "arn:aws:cloudfront::216066926519:distribution/E1AN3BXJ4E5SB7"
      domain_name    = "d35hy35365nsmp.cloudfront.net"
      hosted_zone_id = "Z2FDTNDATAQYW2"
    }
  }
}

run "creates_cloudfront_dns_aliases" {
  command = apply

  variables {
    domain_name = "frankidugboe.com"
  }

  assert {
    condition     = aws_route53_record.apex_a.name == "frankidugboe.com"
    error_message = "The apex domain must have an A alias record."
  }

  assert {
    condition     = aws_route53_record.apex_a.type == "A"
    error_message = "The apex IPv4 record must use type A."
  }

  assert {
    condition     = aws_route53_record.apex_a.alias[0].name == module.cloudfront.distribution_domain_name
    error_message = "The apex A record must target the CloudFront distribution."
  }

  assert {
    condition     = aws_route53_record.apex_a.alias[0].zone_id == module.cloudfront.hosted_zone_id
    error_message = "The apex A record must use the CloudFront hosted zone ID."
  }

  assert {
    condition     = aws_route53_record.apex_a.alias[0].evaluate_target_health == false
    error_message = "The apex A alias must not evaluate target health."
  }

  assert {
    condition     = aws_route53_record.apex_aaaa.name == "frankidugboe.com"
    error_message = "The apex domain must have an AAAA alias record."
  }

  assert {
    condition     = aws_route53_record.apex_aaaa.type == "AAAA"
    error_message = "The apex IPv6 record must use type AAAA."
  }

  assert {
    condition     = aws_route53_record.apex_aaaa.alias[0].name == module.cloudfront.distribution_domain_name
    error_message = "The apex AAAA record must target the CloudFront distribution."
  }

  assert {
    condition     = aws_route53_record.apex_aaaa.alias[0].zone_id == module.cloudfront.hosted_zone_id
    error_message = "The apex AAAA record must use the CloudFront hosted zone ID."
  }

  assert {
    condition     = aws_route53_record.apex_aaaa.alias[0].evaluate_target_health == false
    error_message = "The apex AAAA alias must not evaluate target health."
  }

  assert {
    condition     = aws_route53_record.www_a.name == "www.frankidugboe.com"
    error_message = "www must have an A alias record."
  }

  assert {
    condition     = aws_route53_record.www_a.type == "A"
    error_message = "The www IPv4 record must use type A."
  }

  assert {
    condition     = aws_route53_record.www_a.alias[0].name == module.cloudfront.distribution_domain_name
    error_message = "The www A record must target the CloudFront distribution."
  }

  assert {
    condition     = aws_route53_record.www_a.alias[0].zone_id == module.cloudfront.hosted_zone_id
    error_message = "The www A record must use the CloudFront hosted zone ID."
  }

  assert {
    condition     = aws_route53_record.www_a.alias[0].evaluate_target_health == false
    error_message = "The www A alias must not evaluate target health."
  }

  assert {
    condition     = aws_route53_record.www_aaaa.name == "www.frankidugboe.com"
    error_message = "www must have an AAAA alias record."
  }

  assert {
    condition     = aws_route53_record.www_aaaa.type == "AAAA"
    error_message = "The www IPv6 record must use type AAAA."
  }

  assert {
    condition     = aws_route53_record.www_aaaa.alias[0].name == module.cloudfront.distribution_domain_name
    error_message = "The www AAAA record must target the CloudFront distribution."
  }

  assert {
    condition     = aws_route53_record.www_aaaa.alias[0].zone_id == module.cloudfront.hosted_zone_id
    error_message = "The www AAAA record must use the CloudFront hosted zone ID."
  }

  assert {
    condition     = aws_route53_record.www_aaaa.alias[0].evaluate_target_health == false
    error_message = "The www AAAA alias must not evaluate target health."
  }
}
