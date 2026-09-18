mock_provider "aws" {}

run "configures_contact_http_api" {
  command = plan

  variables {
    name                 = "frankidugboe-com-contact"
    lambda_invoke_arn    = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:123456789012:function:contact/invocations"
    lambda_function_name = "frankidugboe-com-contact"
  }

  assert {
    condition     = aws_apigatewayv2_api.this.protocol_type == "HTTP"
    error_message = "The API must be an HTTP API."
  }

  assert {
    condition     = aws_apigatewayv2_route.contact.route_key == "POST /api/contact"
    error_message = "The contact route must be POST /api/contact to match the CloudFront-forwarded path."
  }

  assert {
    condition     = aws_apigatewayv2_integration.lambda.integration_type == "AWS_PROXY"
    error_message = "The integration must be a Lambda proxy integration."
  }

  assert {
    condition     = aws_apigatewayv2_stage.default.default_route_settings[0].throttling_rate_limit == 10
    error_message = "The stage must apply steady-state throttling."
  }

  assert {
    condition     = aws_lambda_permission.apigw.principal == "apigateway.amazonaws.com"
    error_message = "API Gateway must be permitted to invoke the function."
  }
}
