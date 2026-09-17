mock_provider "aws" {}

run "creates_public_hosted_zone" {
  command = plan

  variables {
    domain_name = "frankidugboe.com"
  }

  assert {
    condition     = aws_route53_zone.this.name == "frankidugboe.com"
    error_message = "The hosted zone must use frankidugboe.com."
  }

  assert {
    condition     = aws_route53_zone.this.force_destroy == false
    error_message = "The hosted zone must not allow forced destruction."
  }
}
