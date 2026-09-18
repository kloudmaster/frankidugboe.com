variable "domain_name" {
  description = "Domain name for the public Route 53 hosted zone."
  type        = string
}

variable "query_logging_enabled" {
  description = "Enable DNS query logging to CloudWatch Logs (requires us-east-1)."
  type        = bool
  default     = false
}

variable "query_log_retention_days" {
  description = "Retention period for Route 53 query logs."
  type        = number
  default     = 30
}
