mock_provider "aws" {}
mock_provider "archive" {}

run "configures_contact_function" {
  command = plan

  variables {
    function_name      = "frankidugboe-com-contact"
    source_dir         = "tests/fixtures"
    execution_role_arn = "arn:aws:iam::123456789012:role/frankidugboe-com-contact-exec"
    ses_sender         = "no-reply@frankidugboe.com"
    ses_recipient      = "private@frankidugboe.com"
  }

  assert {
    condition     = aws_lambda_function.this.runtime == "nodejs20.x"
    error_message = "The function must use the nodejs20.x runtime."
  }

  assert {
    condition     = aws_lambda_function.this.handler == "index.handler"
    error_message = "The handler must be index.handler."
  }

  assert {
    condition     = aws_lambda_function.this.role == "arn:aws:iam::123456789012:role/frankidugboe-com-contact-exec"
    error_message = "The function must use the externally provided execution role."
  }

  assert {
    condition     = aws_lambda_function.this.reserved_concurrent_executions == 5
    error_message = "Reserved concurrency must cap abuse blast radius."
  }

  assert {
    condition     = aws_lambda_function.this.environment[0].variables.SES_SENDER == "no-reply@frankidugboe.com"
    error_message = "The SES sender must be injected into the environment."
  }

  assert {
    condition     = aws_cloudwatch_log_group.this.retention_in_days == 30
    error_message = "The log group must set a retention period."
  }
}
