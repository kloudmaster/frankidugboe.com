variable "name" {
  description = "Name of the HTTP API."
  type        = string
}

variable "lambda_invoke_arn" {
  description = "Invoke ARN of the Lambda integration target."
  type        = string
}

variable "lambda_function_name" {
  description = "Name of the Lambda function to grant invoke permission."
  type        = string
}

variable "route_path" {
  description = "Path for the contact route. CloudFront forwards the full /api/* path without stripping, so this includes the /api prefix."
  type        = string
  default     = "/api/contact"
}

variable "log_retention_days" {
  description = "Access log retention in days."
  type        = number
  default     = 30
}

variable "throttling_burst_limit" {
  description = "API Gateway burst throttling limit."
  type        = number
  default     = 20
}

variable "throttling_rate_limit" {
  description = "API Gateway steady-state throttling rate (requests/second)."
  type        = number
  default     = 10
}
