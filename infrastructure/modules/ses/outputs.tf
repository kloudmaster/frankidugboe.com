output "domain_identity" {
  description = "The SES verified domain identity."
  value       = aws_sesv2_email_identity.domain.email_identity
}

output "domain_identity_arn" {
  description = "ARN of the SES domain identity."
  value       = aws_sesv2_email_identity.domain.arn
}
