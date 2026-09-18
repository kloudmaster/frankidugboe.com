locals {
  validation_domains = toset(
    concat(
      [var.domain_name],
      var.subject_alternative_names,
    )
  )
}

resource "aws_acm_certificate" "this" {
  domain_name               = var.domain_name
  subject_alternative_names = var.subject_alternative_names
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = var.domain_name
  }
}

resource "aws_route53_record" "validation" {
  for_each = local.validation_domains

  zone_id = var.route53_zone_id

  name = one([
    for option in aws_acm_certificate.this.domain_validation_options :
    option.resource_record_name
    if option.domain_name == each.key
  ])

  type = one([
    for option in aws_acm_certificate.this.domain_validation_options :
    option.resource_record_type
    if option.domain_name == each.key
  ])

  records = [
    one([
      for option in aws_acm_certificate.this.domain_validation_options :
      option.resource_record_value
      if option.domain_name == each.key
    ])
  ]

  ttl             = 60
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "this" {
  certificate_arn = aws_acm_certificate.this.arn

  validation_record_fqdns = [
    for record in aws_route53_record.validation :
    record.fqdn
  ]
}
