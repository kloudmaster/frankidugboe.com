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

variable "web_acl_arn" {
  description = "ARN of the WAFv2 (CLOUDFRONT scope) Web ACL to associate. Empty disables association."
  type        = string
  default     = ""
}

variable "api_origin_domain_name" {
  description = "Hostname of the contact API (API Gateway) origin. Empty disables the /api/* behavior."
  type        = string
  default     = ""
}

variable "api_path_pattern" {
  description = "Path pattern routed to the API origin."
  type        = string
  default     = "/api/*"
}

variable "log_bucket_domain_name" {
  description = "Log bucket domain name for CloudFront access logging. Empty disables logging."
  type        = string
  default     = ""
}

variable "logging_enabled" {
  description = "Enable CloudFront access logging (statically known so the block is plannable)."
  type        = bool
  default     = false
}
