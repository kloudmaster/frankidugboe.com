output "bucket_name" {
  description = "Name of the private S3 origin bucket."
  value       = aws_s3_bucket.this.bucket
}

output "bucket_arn" {
  description = "ARN of the private S3 origin bucket."
  value       = aws_s3_bucket.this.arn
}

output "bucket_regional_domain_name" {
  description = "Regional domain name used by CloudFront as the S3 origin."
  value       = aws_s3_bucket.this.bucket_regional_domain_name
}
