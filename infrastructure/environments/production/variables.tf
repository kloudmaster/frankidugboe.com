variable "aws_region" {
  description = "Primary AWS region for the portfolio infrastructure."
  type        = string
  default     = "us-east-1"
}

variable "domain_name" {
  description = "Canonical domain for the portfolio."
  type        = string
  default     = "frankidugboe.com"
}
