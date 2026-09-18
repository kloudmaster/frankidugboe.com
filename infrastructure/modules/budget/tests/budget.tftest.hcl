mock_provider "aws" {}

run "configures_budget_and_alarm" {
  command = plan

  variables {
    name_prefix          = "frankidugboe-com"
    alert_email          = "kloudmaster001@gmail.com"
    monthly_limit_usd    = "10"
    lambda_function_name = "frankidugboe-com-contact"
  }

  assert {
    condition     = aws_budgets_budget.monthly.budget_type == "COST"
    error_message = "The budget must track cost."
  }

  assert {
    condition     = aws_budgets_budget.monthly.time_unit == "MONTHLY"
    error_message = "The budget must be monthly."
  }

  assert {
    condition     = length(aws_budgets_budget.monthly.notification) == 2
    error_message = "The budget must notify on actual and forecasted thresholds."
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.lambda_errors.metric_name == "Errors"
    error_message = "The alarm must watch Lambda Errors."
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.lambda_errors.dimensions.FunctionName == "frankidugboe-com-contact"
    error_message = "The alarm must target the contact function."
  }
}
