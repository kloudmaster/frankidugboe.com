variable "name" {
  description = "Name used for the CloudFront distribution and origin access control."
  type        = string
}

variable "origin_domain_name" {
  description = "Regional domain name of the private S3 origin bucket."
  type        = string
}

variable "acm_certificate_arn" {
  description = "ARN of the ACM certificate used by CloudFront."
  type        = string
}

variable "aliases" {
  description = "Custom domain names served by the CloudFront distribution."
  type        = list(string)
}

variable "origin_bucket_name" {
  description = "Name of the private S3 bucket used as the CloudFront origin."
  type        = string
}

variable "origin_bucket_arn" {
  description = "ARN of the private S3 bucket used as the CloudFront origin."
  type        = string
}
