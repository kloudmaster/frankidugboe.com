locals {
  mail_from_domain = "mail.${var.domain_name}"

  # Amazon SES Easy DKIM returns three signing tokens at apply time. Guard the
  # computed lookup with try() so plan/validate and `terraform test` mocks
  # (where the value is not yet known) do not error on an empty list.
  dkim_tokens = try(
    aws_sesv2_email_identity.domain.dkim_signing_attributes[0].tokens,
    [],
  )
}

# Verify the sending domain so any address on it can send (e.g. no-reply@).
resource "aws_sesv2_email_identity" "domain" {
  email_identity = var.domain_name

  tags = {
    Name = var.domain_name
  }
}

# Publish one DKIM CNAME record per SES-issued token so the domain's mail is
# signed and trusted.
resource "aws_route53_record" "dkim" {
  for_each = toset(local.dkim_tokens)

  zone_id = var.route53_zone_id
  name    = "${each.value}._domainkey.${var.domain_name}"
  type    = "CNAME"
  ttl     = 1800
  records = ["${each.value}.dkim.amazonses.com"]

  allow_overwrite = true
}

# Custom MAIL FROM domain improves SPF alignment.
resource "aws_sesv2_email_identity_mail_from_attributes" "domain" {
  email_identity   = aws_sesv2_email_identity.domain.email_identity
  mail_from_domain = local.mail_from_domain

  behavior_on_mx_failure = "USE_DEFAULT_VALUE"
}

resource "aws_route53_record" "mail_from_mx" {
  zone_id = var.route53_zone_id
  name    = local.mail_from_domain
  type    = "MX"
  ttl     = 1800
  records = ["10 feedback-smtp.${var.aws_region}.amazonses.com"]

  allow_overwrite = true
}

resource "aws_route53_record" "mail_from_spf" {
  zone_id = var.route53_zone_id
  name    = local.mail_from_domain
  type    = "TXT"
  ttl     = 1800
  records = ["v=spf1 include:amazonses.com -all"]

  allow_overwrite = true
}
