output "bucket_name" {
  description = "Name of the access-log destination bucket."
  value       = aws_s3_bucket.logs.id
}

output "bucket_arn" {
  description = "ARN of the access-log destination bucket."
  value       = aws_s3_bucket.logs.arn
}

output "bucket_domain_name" {
  description = "Regional domain name of the log bucket, for CloudFront logging_config."
  value       = aws_s3_bucket.logs.bucket_domain_name
}
