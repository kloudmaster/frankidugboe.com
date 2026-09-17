output "route53_zone_id" {
  description = "Route 53 hosted zone ID for the portfolio domain."
  value       = module.route53.zone_id
}

output "route53_name_servers" {
  description = "Authoritative Route 53 name servers to configure at Porkbun."
  value       = module.route53.name_servers
}
