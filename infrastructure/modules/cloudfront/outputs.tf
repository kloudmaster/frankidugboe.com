output "distribution_id" {
  description = "ID of the CloudFront distribution."
  value       = aws_cloudfront_distribution.this.id
}

output "distribution_arn" {
  description = "ARN of the CloudFront distribution."
  value       = aws_cloudfront_distribution.this.arn
}

output "distribution_domain_name" {
  description = "AWS-assigned domain name of the CloudFront distribution."
  value       = aws_cloudfront_distribution.this.domain_name
}

output "origin_access_control_id" {
  description = "ID of the CloudFront Origin Access Control."
  value       = aws_cloudfront_origin_access_control.this.id
}

output "hosted_zone_id" {
  description = "Route 53 hosted zone ID used by the CloudFront distribution."
  value       = aws_cloudfront_distribution.this.hosted_zone_id
}
