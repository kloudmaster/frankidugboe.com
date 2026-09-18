mock_provider "aws" {
  mock_data "aws_canonical_user_id" {
    defaults = {
      id = "mockcanonicaluserid0000000000000000000000000000000000000000000000"
    }
  }

  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "216066926519"
    }
  }

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  mock_resource "aws_route53_zone" {
    defaults = {
      zone_id = "Z05203182KTV9HKTZIEXD"

      name_servers = [
        "ns-1472.awsdns-56.org",
        "ns-1820.awsdns-35.co.uk",
        "ns-243.awsdns-30.com",
        "ns-658.awsdns-18.net",
      ]
    }
  }

  mock_resource "aws_acm_certificate" {
    defaults = {
      arn = "arn:aws:acm:us-east-1:216066926519:certificate/test-certificate"

      domain_validation_options = [
        {
          domain_name           = "frankidugboe.com"
          resource_record_name  = "_test.frankidugboe.com."
          resource_record_type  = "CNAME"
          resource_record_value = "_validation.acm-validations.aws."
        },
        {
          domain_name           = "www.frankidugboe.com"
          resource_record_name  = "_test.www.frankidugboe.com."
          resource_record_type  = "CNAME"
          resource_record_value = "_validation-www.acm-validations.aws."
        },
      ]
    }
  }

  mock_resource "aws_cloudfront_function" {
    defaults = {
      arn = "arn:aws:cloudfront::216066926519:function/frankidugboe-com-viewer-request"
    }
  }

  mock_resource "aws_cloudfront_distribution" {
    defaults = {
      id             = "E1AN3BXJ4E5SB7"
      arn            = "arn:aws:cloudfront::216066926519:distribution/E1AN3BXJ4E5SB7"
      domain_name    = "d35hy35365nsmp.cloudfront.net"
      hosted_zone_id = "Z2FDTNDATAQYW2"
    }
  }

  mock_resource "aws_iam_openid_connect_provider" {
    defaults = {
      arn = "arn:aws:iam::216066926519:oidc-provider/token.actions.githubusercontent.com"
    }
  }

  mock_resource "aws_wafv2_web_acl" {
    defaults = {
      arn = "arn:aws:wafv2:us-east-1:216066926519:global/webacl/frankidugboe-com-waf/mock"
    }
  }

  mock_resource "aws_sns_topic" {
    defaults = {
      arn = "arn:aws:sns:us-east-1:216066926519:frankidugboe-com-alerts"
    }
  }

  mock_resource "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::216066926519:role/mock-github-role"
    }
  }

  mock_resource "aws_cloudwatch_log_group" {
    defaults = {
      arn = "arn:aws:logs:us-east-1:216066926519:log-group:/aws/mock:*"
    }
  }

  mock_resource "aws_apigatewayv2_api" {
    defaults = {
      id            = "mockapiid00"
      api_endpoint  = "https://mockapiid00.execute-api.us-east-1.amazonaws.com"
      execution_arn = "arn:aws:execute-api:us-east-1:216066926519:mockapiid00"
    }
  }
}

mock_provider "archive" {}

run "composes_github_oidc_iam" {
  command = apply

  variables {
    domain_name   = "frankidugboe.com"
    ses_recipient = "private@frankidugboe.com"
  }

  assert {
    condition     = output.github_plan_role_arn == module.iam.github_plan_role_arn
    error_message = "Production must expose the GitHub Terraform plan role ARN."
  }

  assert {
    condition     = output.github_deploy_role_arn == module.iam.github_deploy_role_arn
    error_message = "Production must expose the GitHub production deploy role ARN."
  }
}
