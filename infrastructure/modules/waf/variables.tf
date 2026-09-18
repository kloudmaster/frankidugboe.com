variable "name" {
  description = "Name of the WAFv2 Web ACL."
  type        = string
}

variable "rate_limit" {
  description = "Max requests allowed from a single IP over a 5-minute window."
  type        = number
  default     = 1000
}
