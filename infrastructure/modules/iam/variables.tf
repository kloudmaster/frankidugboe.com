variable "github_repository_owner" {
  description = "GitHub repository owner permitted to federate with AWS."
  type        = string
}

variable "github_repository_name" {
  description = "GitHub repository name permitted to federate with AWS."
  type        = string
}

variable "github_repository_owner_id" {
  description = "Immutable GitHub repository owner ID used in OIDC subjects."
  type        = string
}

variable "github_repository_id" {
  description = "Immutable GitHub repository ID used in OIDC subjects."
  type        = string
}

variable "state_bucket_name" {
  description = "S3 bucket containing the production Terraform state."
  type        = string
}

variable "state_key" {
  description = "Exact S3 key containing the production Terraform state."
  type        = string
}

variable "site_bucket_name" {
  description = "Private S3 origin bucket containing the portfolio site."
  type        = string
}

variable "cloudfront_distribution_arn" {
  description = "ARN of the portfolio CloudFront distribution."
  type        = string
}

variable "route53_zone_id" {
  description = "Route 53 hosted zone ID for the portfolio domain."
  type        = string
}

variable "acm_certificate_arn" {
  description = "ARN of the ACM certificate used by the portfolio."
  type        = string
}
