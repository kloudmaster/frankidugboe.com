mock_provider "aws" {
  mock_resource "aws_cloudfront_function" {
    defaults = {
      arn = "arn:aws:cloudfront::123456789012:function/frankidugboe-com-viewer-request"
    }
  }

  mock_resource "aws_cloudfront_distribution" {
    defaults = {
      arn = "arn:aws:cloudfront::123456789012:distribution/E123456789TEST"
    }
  }
}

run "creates_sigv4_s3_origin_access_control" {
  command = plan

  variables {
    name                = "frankidugboe.com"
    origin_domain_name  = "frankidugboe-com-origin-216066926519.s3.us-east-1.amazonaws.com"
    origin_bucket_name  = "frankidugboe-com-origin-216066926519"
    origin_bucket_arn   = "arn:aws:s3:::frankidugboe-com-origin-216066926519"
    acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/test"
    aliases             = ["frankidugboe.com", "www.frankidugboe.com"]
  }

  assert {
    condition     = aws_cloudfront_origin_access_control.this.origin_access_control_origin_type == "s3"
    error_message = "The CloudFront origin access control must target an S3 origin."
  }

  assert {
    condition     = aws_cloudfront_origin_access_control.this.signing_behavior == "always"
    error_message = "CloudFront must always sign requests to the private S3 origin."
  }

  assert {
    condition     = aws_cloudfront_origin_access_control.this.signing_protocol == "sigv4"
    error_message = "CloudFront must use SigV4 when signing requests to S3."
  }
}

run "configures_secure_static_site_distribution" {
  command = plan

  variables {
    name                = "frankidugboe.com"
    origin_domain_name  = "frankidugboe-com-origin-216066926519.s3.us-east-1.amazonaws.com"
    origin_bucket_name  = "frankidugboe-com-origin-216066926519"
    origin_bucket_arn   = "arn:aws:s3:::frankidugboe-com-origin-216066926519"
    acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/test"
    aliases             = ["frankidugboe.com", "www.frankidugboe.com"]
  }

  assert {
    condition     = aws_cloudfront_distribution.this.enabled == true
    error_message = "The CloudFront distribution must be enabled."
  }

  assert {
    condition     = aws_cloudfront_distribution.this.is_ipv6_enabled == true
    error_message = "IPv6 must be enabled."
  }

  assert {
    condition     = aws_cloudfront_distribution.this.default_root_object == "index.html"
    error_message = "The default root object must be index.html."
  }

  assert {
    condition     = contains(aws_cloudfront_distribution.this.aliases, "frankidugboe.com")
    error_message = "The distribution must include frankidugboe.com."
  }

  assert {
    condition     = contains(aws_cloudfront_distribution.this.aliases, "www.frankidugboe.com")
    error_message = "The distribution must include www.frankidugboe.com."
  }

  assert {
    condition     = aws_cloudfront_distribution.this.default_cache_behavior[0].viewer_protocol_policy == "redirect-to-https"
    error_message = "HTTP traffic must redirect to HTTPS."
  }

  assert {
    condition     = aws_cloudfront_distribution.this.default_cache_behavior[0].compress == true
    error_message = "CloudFront compression must be enabled."
  }

  assert {
    condition = (
      toset(aws_cloudfront_distribution.this.default_cache_behavior[0].allowed_methods)
      == toset(["GET", "HEAD"])
    )
    error_message = "Only GET and HEAD must be allowed."
  }

  assert {
    condition = (
      toset(aws_cloudfront_distribution.this.default_cache_behavior[0].cached_methods)
      == toset(["GET", "HEAD"])
    )
    error_message = "Only GET and HEAD must be cached."
  }

  assert {
    condition     = aws_cloudfront_distribution.this.viewer_certificate[0].minimum_protocol_version == "TLSv1.2_2021"
    error_message = "CloudFront must enforce TLSv1.2_2021 or newer."
  }

  assert {
    condition = (
      aws_cloudfront_distribution.this.default_cache_behavior[0].response_headers_policy_id
      == "67f7725c-6f97-4210-82d7-5512b31e9d03"
    )
    error_message = "CloudFront must attach the AWS managed SecurityHeadersPolicy."
  }
}

run "attaches_viewer_request_function" {
  command = plan

  variables {
    name                = "frankidugboe.com"
    origin_domain_name  = "frankidugboe-com-origin-216066926519.s3.us-east-1.amazonaws.com"
    origin_bucket_name  = "frankidugboe-com-origin-216066926519"
    origin_bucket_arn   = "arn:aws:s3:::frankidugboe-com-origin-216066926519"
    acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/test"
    aliases             = ["frankidugboe.com", "www.frankidugboe.com"]
  }

  assert {
    condition     = aws_cloudfront_function.viewer_request.runtime == "cloudfront-js-2.0"
    error_message = "The viewer-request function must use the CloudFront JavaScript 2.0 runtime."
  }

  assert {
    condition     = aws_cloudfront_function.viewer_request.publish == true
    error_message = "The viewer-request function must be published."
  }

  assert {
    condition = (
      one(
        aws_cloudfront_distribution.this
        .default_cache_behavior[0]
        .function_association
      ).event_type == "viewer-request"
    )
    error_message = "The CloudFront Function must run on viewer-request."
  }
}

run "maps_missing_origin_objects_to_404_page" {
  command = plan

  variables {
    name                = "frankidugboe.com"
    origin_domain_name  = "frankidugboe-com-origin-216066926519.s3.us-east-1.amazonaws.com"
    origin_bucket_name  = "frankidugboe-com-origin-216066926519"
    origin_bucket_arn   = "arn:aws:s3:::frankidugboe-com-origin-216066926519"
    acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/test"
    aliases             = ["frankidugboe.com", "www.frankidugboe.com"]
  }

  assert {
    condition = length([
      for response in aws_cloudfront_distribution.this.custom_error_response :
      response
      if response.error_code == 403
      && response.response_code == 404
      && response.response_page_path == "/404.html"
    ]) == 1

    error_message = "CloudFront must map S3 403 responses to /404.html with HTTP 404."
  }

  assert {
    condition = length([
      for response in aws_cloudfront_distribution.this.custom_error_response :
      response
      if response.error_code == 404
      && response.response_code == 404
      && response.response_page_path == "/404.html"
    ]) == 1

    error_message = "CloudFront must map S3 404 responses to /404.html with HTTP 404."
  }
}

run "restricts_s3_origin_access_to_cloudfront_distribution" {
  command = apply

  variables {
    name                = "frankidugboe.com"
    origin_domain_name  = "frankidugboe-com-origin-216066926519.s3.us-east-1.amazonaws.com"
    origin_bucket_name  = "frankidugboe-com-origin-216066926519"
    origin_bucket_arn   = "arn:aws:s3:::frankidugboe-com-origin-216066926519"
    acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/test"
    aliases             = ["frankidugboe.com", "www.frankidugboe.com"]
  }

  assert {
    condition     = aws_s3_bucket_policy.origin.bucket == "frankidugboe-com-origin-216066926519"
    error_message = "The bucket policy must protect the portfolio origin bucket."
  }

  assert {
    condition = (
      jsondecode(aws_s3_bucket_policy.origin.policy)
      .Statement[0]
      .Principal.Service == "cloudfront.amazonaws.com"
    )

    error_message = "Only the CloudFront service principal may read through this policy."
  }

  assert {
    condition = (
      jsondecode(aws_s3_bucket_policy.origin.policy)
      .Statement[0]
      .Action == "s3:GetObject"
    )

    error_message = "The CloudFront policy must grant only s3:GetObject."
  }

  assert {
    condition = (
      jsondecode(aws_s3_bucket_policy.origin.policy)
      .Statement[0]
      .Resource == "arn:aws:s3:::frankidugboe-com-origin-216066926519/*"
    )

    error_message = "CloudFront access must be limited to objects in the portfolio origin bucket."
  }

  assert {
    condition = (
      jsondecode(aws_s3_bucket_policy.origin.policy)
      .Statement[0]
      .Condition.StringEquals["AWS:SourceArn"]
      == aws_cloudfront_distribution.this.arn
    )

    error_message = "S3 access must be restricted to this exact CloudFront distribution ARN."
  }
}
