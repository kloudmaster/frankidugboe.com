variable "bucket_name" {
  description = "Name of the access-log destination bucket."
  type        = string
}

variable "log_expiration_days" {
  description = "Number of days after which delivered logs expire."
  type        = number
  default     = 90
}
