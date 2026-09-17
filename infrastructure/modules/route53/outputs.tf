output "zone_id" {
  description = "Route 53 hosted zone ID."
  value       = aws_route53_zone.this.zone_id
}

output "name_servers" {
  description = "Authoritative Route 53 name servers for the domain."
  value       = aws_route53_zone.this.name_servers
}
