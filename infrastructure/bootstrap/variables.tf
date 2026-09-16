variable "aws_region" {
  description = "AWS region used for the Terraform state backend."
  type        = string
  default     = "us-east-1"
}

variable "state_bucket_name" {
  description = "Globally unique S3 bucket name for Terraform remote state."
  type        = string
  default     = "frankidugboe-com-terraform-state-216066926519"
}
