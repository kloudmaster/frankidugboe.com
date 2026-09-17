variable "domain_name" {
  description = "Primary domain name for the ACM certificate."
  type        = string
}

variable "subject_alternative_names" {
  description = "Additional domain names covered by the certificate."
  type        = list(string)
  default     = []
}

variable "route53_zone_id" {
  description = "Route 53 hosted zone ID used for ACM DNS validation."
  type        = string
}
