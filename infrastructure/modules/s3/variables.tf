variable "bucket_name" {
  description = "Name of the private S3 bucket used as the CloudFront origin."
  type        = string
}

variable "log_bucket_name" {
  description = "Destination bucket for S3 server access logs. Empty disables access logging."
  type        = string
  default     = ""
}

variable "logging_enabled" {
  description = "Enable S3 server access logging (statically known so count is plannable)."
  type        = bool
  default     = false
}
