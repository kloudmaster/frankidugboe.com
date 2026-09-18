mock_provider "aws" {}

run "configures_cloudfront_scoped_web_acl" {
  command = plan

  variables {
    name       = "frankidugboe-com-waf"
    rate_limit = 1000
  }

  assert {
    condition     = aws_wafv2_web_acl.this.scope == "CLOUDFRONT"
    error_message = "The Web ACL must be CLOUDFRONT-scoped to attach to the distribution."
  }

  # Three rules: common rule set, known bad inputs (Log4j), and rate limiting.
  assert {
    condition     = length(aws_wafv2_web_acl.this.rule) == 3
    error_message = "The Web ACL must define common, known-bad-inputs and rate-limit rules."
  }

  assert {
    condition = anytrue([
      for r in aws_wafv2_web_acl.this.rule :
      length(r.statement[0].managed_rule_group_statement) > 0 &&
      r.statement[0].managed_rule_group_statement[0].name == "AWSManagedRulesKnownBadInputsRuleSet"
    ])
    error_message = "The Known Bad Inputs rule set (Log4j coverage) must be present."
  }
}
