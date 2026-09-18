variable "name" {
  description = "Name of the WAFv2 Web ACL."
  type        = string
}

variable "rate_limit" {
  description = "Max requests allowed from a single IP over a 5-minute window."
  type        = number
  default     = 1000
}

variable "logging_enabled" {
  description = "Enable WAF logging to a CloudWatch log group (aws-waf-logs-*)."
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "Retention period for WAF logs."
  type        = number
  default     = 30
}
