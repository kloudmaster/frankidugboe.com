output "route53_zone_id" {
  description = "Route 53 hosted zone ID for the portfolio domain."
  value       = module.route53.zone_id
}

output "route53_name_servers" {
  description = "Authoritative Route 53 name servers to configure at Porkbun."
  value       = module.route53.name_servers
}

output "acm_certificate_arn" {
  description = "ARN of the validated ACM certificate for the portfolio domain."
  value       = module.acm.certificate_arn
}

output "s3_origin_bucket_name" {
  description = "Name of the private S3 bucket used as the CloudFront origin."
  value       = module.s3.bucket_name
}

output "s3_origin_bucket_arn" {
  description = "ARN of the private S3 bucket used as the CloudFront origin."
  value       = module.s3.bucket_arn
}

output "s3_origin_regional_domain_name" {
  description = "Regional S3 domain name that CloudFront will use as its origin."
  value       = module.s3.bucket_regional_domain_name
}
