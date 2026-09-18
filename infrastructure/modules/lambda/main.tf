data "archive_file" "this" {
  type        = "zip"
  source_file = "${var.source_dir}/index.js"
  output_path = "${path.module}/build/${var.function_name}.zip"
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "/aws/lambda/${var.function_name}"
  }
}

resource "aws_lambda_function" "this" {
  function_name = var.function_name
  role          = var.execution_role_arn
  runtime       = var.runtime
  handler       = "index.handler"
  timeout       = var.timeout_seconds
  memory_size   = var.memory_size

  filename         = data.archive_file.this.output_path
  source_code_hash = data.archive_file.this.output_base64sha256

  environment {
    variables = merge(
      {
        SES_SENDER    = var.ses_sender
        SES_RECIPIENT = var.ses_recipient
      },
      var.additional_environment,
    )
  }

  # Reserved concurrency caps blast radius from a burst/abuse.
  reserved_concurrent_executions = var.reserved_concurrency

  tracing_config {
    mode = "Active"
  }

  depends_on = [
    aws_cloudwatch_log_group.this,
  ]

  tags = {
    Name = var.function_name
  }
}
