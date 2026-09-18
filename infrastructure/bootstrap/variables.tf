variable "aws_region" {
  description = "AWS region used for the Terraform state backend."
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS named profile for local runs. Leave empty in CI so OIDC env credentials are used."
  type        = string
  default     = ""
}

variable "state_bucket_name" {
  description = "Globally unique S3 bucket name for Terraform remote state."
  type        = string
  default     = "frankidugboe-com-terraform-state-216066926519"
}
