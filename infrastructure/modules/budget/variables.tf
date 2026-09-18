variable "name_prefix" {
  description = "Prefix for budget/alarm/SNS resource names."
  type        = string
}

variable "alert_email" {
  description = "Email address that receives budget and alarm notifications."
  type        = string
}

variable "monthly_limit_usd" {
  description = "Monthly cost budget limit in USD."
  type        = string
  default     = "10"
}

variable "lambda_function_name" {
  description = "Name of the Lambda function to alarm on for errors."
  type        = string
}
