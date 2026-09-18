locals {
  origin_id     = "s3-${var.name}"
  api_origin_id = "api-${var.name}"
  function_name = "${replace(var.name, ".", "-")}-viewer-request"

  api_enabled = var.api_origin_domain_name != ""
}

resource "aws_cloudfront_origin_access_control" "this" {
  name                              = var.name
  description                       = "Origin access control for ${var.name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_function" "viewer_request" {
  name    = local.function_name
  runtime = "cloudfront-js-2.0"
  comment = "Viewer request handling for ${var.name}"
  publish = true
  code    = file("${path.module}/viewer-request.js")
}

resource "aws_cloudfront_distribution" "this" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  aliases             = var.aliases
  web_acl_id          = var.web_acl_arn != "" ? var.web_acl_arn : null

  origin {
    domain_name              = var.origin_domain_name
    origin_id                = local.origin_id
    origin_access_control_id = aws_cloudfront_origin_access_control.this.id
  }

  # Contact API origin (API Gateway), added only when configured.
  dynamic "origin" {
    for_each = local.api_enabled ? [1] : []

    content {
      domain_name = var.api_origin_domain_name
      origin_id   = local.api_origin_id

      custom_origin_config {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "https-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    }
  }

  default_cache_behavior {
    target_origin_id       = local.origin_id
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]

    compress = true

    # AWS managed CachingOptimized policy.
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"

    # AWS managed SecurityHeadersPolicy.
    response_headers_policy_id = "67f7725c-6f97-4210-82d7-5512b31e9d03"

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.viewer_request.arn
    }
  }

  # Route /api/* to the contact API. No caching; forward the request as-is.
  dynamic "ordered_cache_behavior" {
    for_each = local.api_enabled ? [1] : []

    content {
      path_pattern           = var.api_path_pattern
      target_origin_id       = local.api_origin_id
      viewer_protocol_policy = "redirect-to-https"

      allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
      cached_methods  = ["GET", "HEAD"]

      # AWS managed CachingDisabled policy.
      cache_policy_id = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"

      # AWS managed AllViewerExceptHostHeader origin request policy: forwards
      # all viewer headers/query/cookies except Host (API Gateway needs its own).
      origin_request_policy_id = "b689b0a8-53d0-40ab-baf2-68738e2966ac"

      # AWS managed SecurityHeadersPolicy (consistent headers on API responses).
      response_headers_policy_id = "67f7725c-6f97-4210-82d7-5512b31e9d03"
    }
  }

  custom_error_response {
    error_code            = 403
    response_code         = 404
    response_page_path    = "/404.html"
    error_caching_min_ttl = 10
  }

  custom_error_response {
    error_code            = 404
    response_code         = 404
    response_page_path    = "/404.html"
    error_caching_min_ttl = 10
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = {
    Name = var.name
  }
}

resource "aws_s3_bucket_policy" "origin" {
  bucket = var.origin_bucket_name

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"

        Principal = {
          Service = "cloudfront.amazonaws.com"
        }

        Action   = "s3:GetObject"
        Resource = "${var.origin_bucket_arn}/*"

        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.this.arn
          }
        }
      }
    ]
  })
}
