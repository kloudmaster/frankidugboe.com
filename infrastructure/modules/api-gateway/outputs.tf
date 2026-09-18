output "api_id" {
  description = "ID of the HTTP API."
  value       = aws_apigatewayv2_api.this.id
}

output "api_endpoint" {
  description = "Default execute-api endpoint of the HTTP API."
  value       = aws_apigatewayv2_api.this.api_endpoint
}

# Hostname (without scheme) for use as a CloudFront origin.
output "api_domain_name" {
  description = "Hostname of the HTTP API for use as a CloudFront origin."
  value       = replace(aws_apigatewayv2_api.this.api_endpoint, "https://", "")
}

output "stage_name" {
  description = "Deployed stage name."
  value       = aws_apigatewayv2_stage.default.name
}
