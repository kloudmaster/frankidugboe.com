variable "domain_name" {
  description = "Domain to verify as an SES sending identity (e.g. frankidugboe.com)."
  type        = string
}

variable "route53_zone_id" {
  description = "Route 53 hosted zone ID used to publish SES DKIM and MAIL FROM records."
  type        = string
}

variable "aws_region" {
  description = "AWS region hosting the SES identity, used for the MAIL FROM MX record."
  type        = string
  default     = "us-east-1"
}
