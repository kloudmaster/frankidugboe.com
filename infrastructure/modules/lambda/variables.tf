variable "function_name" {
  description = "Name of the Lambda function."
  type        = string
}

variable "source_dir" {
  description = "Directory containing the function's index.js entrypoint."
  type        = string
}

variable "execution_role_arn" {
  description = "ARN of the pre-created Lambda execution role (managed in the IAM/security plane)."
  type        = string
}

variable "runtime" {
  description = "Lambda runtime. Node.js 20+ includes AWS SDK v3 at runtime."
  type        = string
  default     = "nodejs20.x"
}

variable "ses_sender" {
  description = "Verified SES sender address used as the email From."
  type        = string
}

variable "ses_recipient" {
  description = "Private destination inbox address."
  type        = string
}

variable "additional_environment" {
  description = "Extra environment variables for the function."
  type        = map(string)
  default     = {}
}

variable "timeout_seconds" {
  description = "Function timeout in seconds."
  type        = number
  default     = 10
}

variable "memory_size" {
  description = "Function memory in MB."
  type        = number
  default     = 256
}

variable "reserved_concurrency" {
  description = "Reserved concurrent executions to cap abuse blast radius."
  type        = number
  default     = 5
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days."
  type        = number
  default     = 30
}
