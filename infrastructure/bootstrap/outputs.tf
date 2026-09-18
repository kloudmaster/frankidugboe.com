output "state_bucket_name" {
  description = "S3 bucket used for Terraform remote state."
  value       = aws_s3_bucket.terraform_state.bucket
}

output "state_bucket_arn" {
  description = "ARN of the Terraform remote-state S3 bucket."
  value       = aws_s3_bucket.terraform_state.arn
}

output "state_bucket_region" {
  description = "Region containing the Terraform remote-state bucket."
  value       = var.aws_region
}
