output "zone_id" {
  description = "Route 53 hosted zone ID."
  value       = aws_route53_zone.this.zone_id
}

output "name_servers" {
  description = "Authoritative Route 53 name servers for the domain."
  value       = aws_route53_zone.this.name_servers
}

output "dnssec_ds_record" {
  description = "DS record to publish at the domain registrar to complete DNSSEC. Null when DNSSEC is disabled."
  value       = var.dnssec_enabled ? aws_route53_key_signing_key.this[0].ds_record : null
}

output "dnssec_key_tag" {
  description = "DNSSEC key tag (needed by some registrars). Null when disabled."
  value       = var.dnssec_enabled ? aws_route53_key_signing_key.this[0].key_tag : null
}

output "dnssec_digest_algorithm" {
  description = "DS digest algorithm type. Null when disabled."
  value       = var.dnssec_enabled ? aws_route53_key_signing_key.this[0].digest_algorithm_type : null
}

output "dnssec_public_key" {
  description = "KSK public key. Null when disabled."
  value       = var.dnssec_enabled ? aws_route53_key_signing_key.this[0].public_key : null
}
