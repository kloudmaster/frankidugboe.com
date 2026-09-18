data "aws_caller_identity" "current" {}

locals {
  origin_bucket_name = "${replace(var.domain_name, ".", "-")}-origin-${data.aws_caller_identity.current.account_id}"
  log_bucket_name    = "${replace(var.domain_name, ".", "-")}-logs-${data.aws_caller_identity.current.account_id}"
}

module "route53" {
  source = "../../modules/route53"

  domain_name           = var.domain_name
  query_logging_enabled = true
}

module "acm" {
  source = "../../modules/acm"

  domain_name               = var.domain_name
  subject_alternative_names = ["www.${var.domain_name}"]
  route53_zone_id           = module.route53.zone_id
}

module "logging" {
  source = "../../modules/logging"

  bucket_name = local.log_bucket_name
}

module "s3" {
  source = "../../modules/s3"

  bucket_name     = local.origin_bucket_name
  log_bucket_name = module.logging.bucket_name
  logging_enabled = true
}

module "ses" {
  source = "../../modules/ses"

  domain_name     = var.domain_name
  route53_zone_id = module.route53.zone_id
  aws_region      = var.aws_region
}

module "lambda" {
  source = "../../modules/lambda"

  function_name      = "${replace(var.domain_name, ".", "-")}-contact"
  source_dir         = "${path.root}/../../../functions/contact"
  execution_role_arn = module.iam.contact_exec_role_arn
  ses_sender         = var.ses_sender
  ses_recipient      = var.ses_recipient
}

module "api_gateway" {
  source = "../../modules/api-gateway"

  name                 = "${replace(var.domain_name, ".", "-")}-contact"
  lambda_invoke_arn    = module.lambda.invoke_arn
  lambda_function_name = module.lambda.function_name
}

module "waf" {
  source = "../../modules/waf"

  name            = "${replace(var.domain_name, ".", "-")}-waf"
  logging_enabled = true
}

module "cloudfront" {
  source = "../../modules/cloudfront"

  name                = var.domain_name
  origin_domain_name  = module.s3.bucket_regional_domain_name
  origin_bucket_name  = module.s3.bucket_name
  origin_bucket_arn   = module.s3.bucket_arn
  acm_certificate_arn = module.acm.certificate_arn

  web_acl_arn            = module.waf.web_acl_arn
  api_origin_domain_name = module.api_gateway.api_domain_name
  log_bucket_domain_name = module.logging.bucket_domain_name
  logging_enabled        = true

  aliases = [
    var.domain_name,
    "www.${var.domain_name}",
  ]
}

module "iam" {
  source = "../../modules/iam"

  github_repository_owner    = "kloudmaster"
  github_repository_name     = "frankidugboe.com"
  github_repository_owner_id = "185924774"
  github_repository_id       = "1373130676"

  state_bucket_name = "frankidugboe-com-terraform-state-216066926519"
  state_key         = "production/terraform.tfstate"

  site_bucket_name            = module.s3.bucket_name
  cloudfront_distribution_arn = module.cloudfront.distribution_arn
  route53_zone_id             = module.route53.zone_id
  acm_certificate_arn         = module.acm.certificate_arn
  contact_sender_address      = var.ses_sender
  log_bucket_name             = module.logging.bucket_name
}

module "budget" {
  source = "../../modules/budget"

  name_prefix          = replace(var.domain_name, ".", "-")
  alert_email          = var.alert_email != "" ? var.alert_email : var.ses_recipient
  monthly_limit_usd    = var.monthly_budget_usd
  lambda_function_name = module.lambda.function_name
}
