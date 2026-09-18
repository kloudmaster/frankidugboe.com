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
  description = "Regional S3 domain name that CloudFront uses as its origin."
  value       = module.s3.bucket_regional_domain_name
}

output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution."
  value       = module.cloudfront.distribution_id
}

output "cloudfront_distribution_arn" {
  description = "ARN of the CloudFront distribution."
  value       = module.cloudfront.distribution_arn
}

output "cloudfront_domain_name" {
  description = "AWS-assigned CloudFront distribution domain name."
  value       = module.cloudfront.distribution_domain_name
}

output "github_plan_role_arn" {
  description = "ARN of the GitHub Actions Terraform plan role."
  value       = module.iam.github_plan_role_arn
}

output "github_deploy_role_arn" {
  description = "ARN of the GitHub Actions production deploy role."
  value       = module.iam.github_deploy_role_arn
}

output "contact_api_endpoint" {
  description = "Default endpoint of the contact HTTP API (fronted by CloudFront /api/*)."
  value       = module.api_gateway.api_endpoint
}

output "contact_function_name" {
  description = "Name of the contact Lambda function."
  value       = module.lambda.function_name
}

output "waf_web_acl_arn" {
  description = "ARN of the CloudFront WAF Web ACL."
  value       = module.waf.web_acl_arn
}

output "ses_domain_identity" {
  description = "The SES verified sending domain identity."
  value       = module.ses.domain_identity
}
