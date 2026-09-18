variable "aws_region" {
  description = "Primary AWS region for the portfolio infrastructure."
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS named profile for local runs. Leave empty in CI so OIDC env credentials are used."
  type        = string
  default     = ""
}

variable "domain_name" {
  description = "Canonical domain for the portfolio."
  type        = string
  default     = "frankidugboe.com"
}

variable "ses_sender" {
  description = "Verified SES sender address used as the contact email From."
  type        = string
  default     = "no-reply@frankidugboe.com"
}

variable "ses_recipient" {
  description = "Private inbox that receives contact submissions. Supply via TF_VAR_ses_recipient; never commit."
  type        = string
}

variable "alert_email" {
  description = "Email for budget/alarm notifications. Defaults to ses_recipient when empty."
  type        = string
  default     = ""
}

variable "monthly_budget_usd" {
  description = "Monthly AWS cost budget limit in USD."
  type        = string
  default     = "10"
}
