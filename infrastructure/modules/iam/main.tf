data "aws_caller_identity" "current" {}

locals {
  github_repository = "${var.github_repository_owner}@${var.github_repository_owner_id}/${var.github_repository_name}@${var.github_repository_id}"
  role_name_prefix  = replace(var.github_repository_name, ".", "-")

  github_plan_assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }

        Action = "sts:AssumeRoleWithWebIdentity"

        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
            "token.actions.githubusercontent.com:sub" = "repo:${local.github_repository}:pull_request"
          }
        }
      }
    ]
  })

  github_deploy_assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }

        Action = "sts:AssumeRoleWithWebIdentity"

        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
            "token.actions.githubusercontent.com:sub" = "repo:${local.github_repository}:environment:production"
          }
        }
      }
    ]
  })
}

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]

  tags = {
    Name = "github-actions"
  }
}

resource "aws_iam_role" "github_plan" {
  name               = "${local.role_name_prefix}-github-plan"
  assume_role_policy = local.github_plan_assume_role_policy

  tags = {
    Name = "${local.role_name_prefix}-github-plan"
  }
}

resource "aws_iam_role" "github_deploy" {
  name               = "${local.role_name_prefix}-github-deploy"
  assume_role_policy = local.github_deploy_assume_role_policy

  tags = {
    Name = "${local.role_name_prefix}-github-deploy"
  }
}

# Execution role for the contact Lambda. Created in the security plane (this
# module) rather than by the deploy pipeline, which deliberately has no IAM
# create/modify permissions. The deploy role only holds iam:PassRole for it.
data "aws_iam_policy_document" "contact_exec_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "contact_exec" {
  name               = "${local.role_name_prefix}-contact-exec"
  assume_role_policy = data.aws_iam_policy_document.contact_exec_assume.json

  tags = {
    Name = "${local.role_name_prefix}-contact-exec"
  }
}

data "aws_iam_policy_document" "contact_exec" {
  statement {
    sid    = "Logging"
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${local.role_name_prefix}-contact:*",
    ]
  }

  statement {
    sid    = "SendEmail"
    effect = "Allow"

    actions = ["ses:SendEmail"]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "ses:FromAddress"
      values   = [var.contact_sender_address]
    }
  }
}

resource "aws_iam_role_policy" "contact_exec" {
  name   = "${local.role_name_prefix}-contact-exec-permissions"
  role   = aws_iam_role.contact_exec.id
  policy = data.aws_iam_policy_document.contact_exec.json
}

locals {
  state_bucket_arn   = "arn:aws:s3:::${var.state_bucket_name}"
  state_object_arn   = "${local.state_bucket_arn}/${var.state_key}"
  state_lockfile_arn = "${local.state_object_arn}.tflock"

  site_bucket_arn  = "arn:aws:s3:::${var.site_bucket_name}"
  site_objects_arn = "${local.site_bucket_arn}/*"

  log_bucket_arn = "arn:aws:s3:::${var.log_bucket_name}"

  route53_zone_arn = "arn:aws:route53:::hostedzone/${var.route53_zone_id}"

  github_plan_permissions_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "TerraformStateRead"
        Effect = "Allow"

        Action = [
          "s3:GetObject",
        ]

        Resource = [
          local.state_object_arn,
        ]
      },
      {
        Sid    = "TerraformLockfileAccess"
        Effect = "Allow"

        Action = [
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:PutObject",
        ]

        Resource = [
          local.state_lockfile_arn,
        ]
      },
      {
        Sid    = "TerraformStateList"
        Effect = "Allow"

        Action = [
          "s3:ListBucket",
        ]

        Resource = [
          local.state_bucket_arn,
        ]

        Condition = {
          StringLike = {
            "s3:prefix" = [
              var.state_key,
            ]
          }
        }
      },
      {
        Sid    = "SiteBucketRead"
        Effect = "Allow"

        Action = [
          "s3:GetAccelerateConfiguration",
          "s3:GetBucketAcl",
          "s3:GetBucketCORS",
          "s3:GetBucketLocation",
          "s3:GetBucketLogging",
          "s3:GetBucketObjectLockConfiguration",
          "s3:GetBucketOwnershipControls",
          "s3:GetBucketPolicy",
          "s3:GetBucketPublicAccessBlock",
          "s3:GetBucketRequestPayment",
          "s3:GetBucketTagging",
          "s3:GetBucketVersioning",
          "s3:GetBucketWebsite",
          "s3:GetEncryptionConfiguration",
          "s3:GetLifecycleConfiguration",
          "s3:GetReplicationConfiguration",
          "s3:ListBucket",
        ]

        Resource = [
          local.site_bucket_arn,
        ]
      },
      {
        Sid    = "LogBucketRead"
        Effect = "Allow"

        Action = [
          "s3:GetAccelerateConfiguration",
          "s3:GetBucketAcl",
          "s3:GetBucketCORS",
          "s3:GetBucketLocation",
          "s3:GetBucketLogging",
          "s3:GetBucketObjectLockConfiguration",
          "s3:GetBucketOwnershipControls",
          "s3:GetBucketPolicy",
          "s3:GetBucketPublicAccessBlock",
          "s3:GetBucketRequestPayment",
          "s3:GetBucketTagging",
          "s3:GetBucketVersioning",
          "s3:GetBucketWebsite",
          "s3:GetEncryptionConfiguration",
          "s3:GetLifecycleConfiguration",
          "s3:GetReplicationConfiguration",
          "s3:ListBucket",
        ]

        Resource = [
          local.log_bucket_arn,
        ]
      },
      {
        Sid    = "CloudFrontRead"
        Effect = "Allow"

        Action = [
          "cloudfront:DescribeFunction",
          "cloudfront:GetDistribution",
          "cloudfront:GetDistributionConfig",
          "cloudfront:GetFunction",
          "cloudfront:GetOriginAccessControl",
          "cloudfront:ListTagsForResource",
        ]

        Resource = [
          "*",
        ]
      },
      {
        Sid    = "Route53Read"
        Effect = "Allow"

        Action = [
          "route53:GetHostedZone",
          "route53:ListResourceRecordSets",
          "route53:ListTagsForResource",
        ]

        Resource = [
          local.route53_zone_arn,
        ]
      },
      {
        Sid    = "AcmRead"
        Effect = "Allow"

        Action = [
          "acm:DescribeCertificate",
          "acm:ListTagsForCertificate",
        ]

        Resource = [
          var.acm_certificate_arn,
        ]
      },
      {
        Sid    = "IamMetadataRead"
        Effect = "Allow"

        Action = [
          "iam:GetOpenIDConnectProvider",
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:ListAttachedRolePolicies",
          "iam:ListRolePolicies",
          "iam:ListRoleTags",
        ]

        Resource = [
          "*",
        ]
      },
      {
        Sid    = "ContactBackendRead"
        Effect = "Allow"

        Action = [
          "lambda:GetFunction",
          "lambda:GetFunctionCodeSigningConfig",
          "lambda:GetFunctionConcurrency",
          "lambda:GetFunctionConfiguration",
          "lambda:GetPolicy",
          "lambda:ListVersionsByFunction",
          "lambda:ListTags",
          "apigateway:GET",
          "ses:GetEmailIdentity",
          "ses:GetEmailIdentityPolicies",
          "ses:ListTagsForResource",
          "wafv2:GetWebACL",
          "wafv2:ListTagsForResource",
          "logs:DescribeLogGroups",
          "logs:ListTagsForResource",
        ]

        Resource = [
          "*",
        ]
      },
      {
        Sid    = "ObservabilityRead"
        Effect = "Allow"

        Action = [
          "budgets:ViewBudget",
          "budgets:DescribeBudget",
          "cloudwatch:DescribeAlarms",
          "cloudwatch:ListTagsForResource",
          "logs:DescribeResourcePolicies",
          "route53:GetQueryLoggingConfig",
          "route53:ListQueryLoggingConfigs",
          "sns:GetTopicAttributes",
          "sns:ListSubscriptionsByTopic",
          "sns:ListTagsForResource",
          "wafv2:GetLoggingConfiguration",
          "s3:GetBucketLogging",
        ]

        Resource = [
          "*",
        ]
      },
    ]
  })

  github_deploy_permissions_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "TerraformStateReadWrite"
        Effect = "Allow"

        Action = [
          "s3:GetObject",
          "s3:PutObject",
        ]

        Resource = [
          local.state_object_arn,
        ]
      },
      {
        Sid    = "TerraformLockfileAccess"
        Effect = "Allow"

        Action = [
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:PutObject",
        ]

        Resource = [
          local.state_lockfile_arn,
        ]
      },
      {
        Sid    = "TerraformStateList"
        Effect = "Allow"

        Action = [
          "s3:ListBucket",
        ]

        Resource = [
          local.state_bucket_arn,
        ]

        Condition = {
          StringLike = {
            "s3:prefix" = [
              var.state_key,
            ]
          }
        }
      },
      {
        Sid    = "SiteBucketManagement"
        Effect = "Allow"

        Action = [
          "s3:CreateBucket",
          "s3:DeleteBucket",
          "s3:DeleteBucketEncryption",
          "s3:DeleteBucketOwnershipControls",
          "s3:DeleteBucketPolicy",
          "s3:DeleteBucketPublicAccessBlock",
          "s3:DeleteBucketTagging",
          "s3:GetAccelerateConfiguration",
          "s3:GetBucketAcl",
          "s3:GetBucketCORS",
          "s3:GetBucketLogging",
          "s3:GetBucketObjectLockConfiguration",
          "s3:GetBucketRequestPayment",
          "s3:GetBucketWebsite",
          "s3:GetLifecycleConfiguration",
          "s3:GetReplicationConfiguration",
          "s3:GetBucketLocation",
          "s3:GetBucketOwnershipControls",
          "s3:GetBucketPolicy",
          "s3:GetBucketPublicAccessBlock",
          "s3:GetBucketTagging",
          "s3:GetBucketVersioning",
          "s3:GetEncryptionConfiguration",
          "s3:ListBucket",
          "s3:PutBucketOwnershipControls",
          "s3:PutBucketPolicy",
          "s3:PutBucketPublicAccessBlock",
          "s3:PutBucketTagging",
          "s3:PutBucketVersioning",
          "s3:PutEncryptionConfiguration",
          "s3:PutLifecycleConfiguration",
        ]

        Resource = [
          local.site_bucket_arn,
        ]
      },
      {
        Sid    = "SiteObjectDeployment"
        Effect = "Allow"

        Action = [
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:PutObject",
        ]

        Resource = [
          local.site_objects_arn,
        ]
      },
      {
        Sid    = "CloudFrontCurrentDistribution"
        Effect = "Allow"

        Action = [
          "cloudfront:CreateInvalidation",
          "cloudfront:GetDistribution",
          "cloudfront:GetDistributionConfig",
          "cloudfront:ListTagsForResource",
        ]

        Resource = [
          var.cloudfront_distribution_arn,
        ]
      },
      {
        Sid    = "CloudFrontDistributionLifecycle"
        Effect = "Allow"

        Action = [
          "cloudfront:CreateDistribution",
          "cloudfront:CreateDistributionWithTags",
          "cloudfront:DeleteDistribution",
          "cloudfront:TagResource",
          "cloudfront:UntagResource",
          "cloudfront:UpdateDistribution",
        ]

        Resource = [
          "*",
        ]
      },
      {
        Sid    = "CloudFrontFunctionAndOacLifecycle"
        Effect = "Allow"

        Action = [
          "cloudfront:CreateFunction",
          "cloudfront:CreateOriginAccessControl",
          "cloudfront:DeleteFunction",
          "cloudfront:DeleteOriginAccessControl",
          "cloudfront:DescribeFunction",
          "cloudfront:GetFunction",
          "cloudfront:GetOriginAccessControl",
          "cloudfront:ListTagsForResource",
          "cloudfront:PublishFunction",
          "cloudfront:UpdateFunction",
          "cloudfront:UpdateOriginAccessControl",
        ]

        Resource = [
          "*",
        ]
      },
      {
        Sid    = "Route53CurrentZone"
        Effect = "Allow"

        Action = [
          "route53:ChangeResourceRecordSets",
          "route53:GetHostedZone",
          "route53:ListResourceRecordSets",
          "route53:ListTagsForResource",
        ]

        Resource = [
          local.route53_zone_arn,
        ]
      },
      {
        Sid    = "Route53Lifecycle"
        Effect = "Allow"

        Action = [
          "route53:ChangeTagsForResource",
          "route53:CreateHostedZone",
          "route53:DeleteHostedZone",
        ]

        Resource = [
          "*",
        ]
      },
      {
        Sid    = "Route53ChangeRead"
        Effect = "Allow"

        Action = [
          "route53:GetChange",
        ]

        Resource = [
          "arn:aws:route53:::change/*",
        ]
      },
      {
        Sid    = "AcmCurrentCertificateRead"
        Effect = "Allow"

        Action = [
          "acm:DescribeCertificate",
          "acm:ListTagsForCertificate",
        ]

        Resource = [
          var.acm_certificate_arn,
        ]
      },
      {
        Sid    = "AcmCertificateLifecycle"
        Effect = "Allow"

        Action = [
          "acm:AddTagsToCertificate",
          "acm:DeleteCertificate",
          "acm:RemoveTagsFromCertificate",
          "acm:RequestCertificate",
        ]

        Resource = [
          "*",
        ]
      },
      {
        Sid    = "IamMetadataRead"
        Effect = "Allow"

        Action = [
          "iam:GetOpenIDConnectProvider",
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:ListAttachedRolePolicies",
          "iam:ListRolePolicies",
          "iam:ListRoleTags",
        ]

        Resource = [
          "*",
        ]
      },
      {
        Sid    = "ContactLambdaManagement"
        Effect = "Allow"

        Action = [
          "lambda:AddPermission",
          "lambda:CreateFunction",
          "lambda:DeleteFunction",
          "lambda:GetFunction",
          "lambda:GetFunctionCodeSigningConfig",
          "lambda:GetFunctionConcurrency",
          "lambda:GetFunctionConfiguration",
          "lambda:GetPolicy",
          "lambda:ListTags",
          "lambda:ListVersionsByFunction",
          "lambda:PutFunctionConcurrency",
          "lambda:RemovePermission",
          "lambda:TagResource",
          "lambda:UntagResource",
          "lambda:UpdateFunctionCode",
          "lambda:UpdateFunctionConfiguration",
        ]

        Resource = [
          "arn:aws:lambda:*:${data.aws_caller_identity.current.account_id}:function:${local.role_name_prefix}-contact",
        ]
      },
      {
        Sid    = "ContactApiGatewayManagement"
        Effect = "Allow"

        Action = [
          "apigateway:DELETE",
          "apigateway:GET",
          "apigateway:PATCH",
          "apigateway:POST",
          "apigateway:PUT",
        ]

        Resource = [
          "arn:aws:apigateway:*::/apis",
          "arn:aws:apigateway:*::/apis/*",
        ]
      },
      {
        Sid    = "ContactSesManagement"
        Effect = "Allow"

        Action = [
          "ses:CreateEmailIdentity",
          "ses:DeleteEmailIdentity",
          "ses:GetEmailIdentity",
          "ses:GetEmailIdentityPolicies",
          "ses:ListTagsForResource",
          "ses:PutEmailIdentityMailFromAttributes",
          "ses:TagResource",
          "ses:UntagResource",
        ]

        Resource = [
          "arn:aws:ses:*:${data.aws_caller_identity.current.account_id}:identity/*",
        ]
      },
      {
        Sid    = "ContactWafManagement"
        Effect = "Allow"

        Action = [
          "wafv2:CreateWebACL",
          "wafv2:DeleteWebACL",
          "wafv2:GetWebACL",
          "wafv2:ListTagsForResource",
          "wafv2:TagResource",
          "wafv2:UntagResource",
          "wafv2:UpdateWebACL",
        ]

        Resource = [
          "arn:aws:wafv2:*:${data.aws_caller_identity.current.account_id}:global/*",
        ]
      },
      {
        Sid    = "ContactLogsManagement"
        Effect = "Allow"

        Action = [
          "logs:CreateLogGroup",
          "logs:DeleteLogGroup",
          "logs:ListTagsForResource",
          "logs:PutRetentionPolicy",
          "logs:TagResource",
          "logs:UntagResource",
        ]

        Resource = [
          "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${local.role_name_prefix}-contact*",
          "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/aws/apigateway/${local.role_name_prefix}-contact*",
        ]
      },
      {
        # DescribeLogGroups is a list operation and does not support
        # resource-level scoping; it must be granted on all log groups.
        Sid    = "ContactLogsDescribe"
        Effect = "Allow"

        Action = [
          "logs:DescribeLogGroups",
        ]

        Resource = [
          "*",
        ]
      },
      {
        # Broad read/list coverage for the contact backend so Terraform's
        # refresh (which reads many attributes across services) never fails on
        # a missing Get/List/Describe. Mutating actions remain resource-scoped
        # in the statements above; this statement grants only reads.
        Sid    = "ContactBackendRefreshRead"
        Effect = "Allow"

        Action = [
          "apigateway:GET",
          "lambda:GetFunction",
          "lambda:GetFunctionCodeSigningConfig",
          "lambda:GetFunctionConcurrency",
          "lambda:GetFunctionConfiguration",
          "lambda:GetPolicy",
          "lambda:ListTags",
          "lambda:ListVersionsByFunction",
          "logs:DescribeLogGroups",
          "logs:ListTagsForResource",
          "ses:GetEmailIdentity",
          "ses:GetEmailIdentityPolicies",
          "ses:ListTagsForResource",
          "wafv2:GetWebACL",
          "wafv2:ListTagsForResource",
        ]

        Resource = [
          "*",
        ]
      },
      {
        Sid    = "ContactExecRolePassRole"
        Effect = "Allow"

        Action = [
          "iam:PassRole",
        ]

        Resource = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.role_name_prefix}-contact-exec",
        ]
      },
      {
        Sid    = "LogBucketManagement"
        Effect = "Allow"

        Action = [
          "s3:CreateBucket",
          "s3:DeleteBucket",
          "s3:GetAccelerateConfiguration",
          "s3:GetBucketAcl",
          "s3:GetBucketCORS",
          "s3:GetBucketLogging",
          "s3:GetBucketObjectLockConfiguration",
          "s3:GetBucketOwnershipControls",
          "s3:GetBucketPolicy",
          "s3:GetBucketPublicAccessBlock",
          "s3:GetBucketRequestPayment",
          "s3:GetBucketTagging",
          "s3:GetBucketVersioning",
          "s3:GetBucketWebsite",
          "s3:GetEncryptionConfiguration",
          "s3:GetLifecycleConfiguration",
          "s3:GetReplicationConfiguration",
          "s3:ListBucket",
          "s3:PutBucketAcl",
          "s3:PutBucketLogging",
          "s3:PutBucketOwnershipControls",
          "s3:PutBucketPolicy",
          "s3:PutBucketPublicAccessBlock",
          "s3:PutBucketTagging",
          "s3:PutBucketVersioning",
          "s3:PutEncryptionConfiguration",
          "s3:PutLifecycleConfiguration",
        ]

        Resource = [
          local.log_bucket_arn,
        ]
      },
      {
        Sid    = "SiteBucketLogging"
        Effect = "Allow"

        Action = [
          "s3:PutBucketLogging",
        ]

        Resource = [
          local.site_bucket_arn,
        ]
      },
      {
        Sid    = "Route53QueryLogging"
        Effect = "Allow"

        Action = [
          "route53:CreateQueryLoggingConfig",
          "route53:DeleteQueryLoggingConfig",
          "route53:GetQueryLoggingConfig",
          "route53:ListQueryLoggingConfigs",
        ]

        Resource = [
          "*",
        ]
      },
      {
        Sid    = "ObservabilityLogsManagement"
        Effect = "Allow"

        Action = [
          "logs:CreateLogGroup",
          "logs:DeleteLogGroup",
          "logs:ListTagsForResource",
          "logs:PutRetentionPolicy",
          "logs:TagResource",
          "logs:UntagResource",
        ]

        Resource = [
          "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/aws/route53/*",
          "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:aws-waf-logs-*",
        ]
      },
      {
        Sid    = "LogsResourcePolicy"
        Effect = "Allow"

        Action = [
          "logs:DeleteResourcePolicy",
          "logs:DescribeResourcePolicies",
          "logs:PutResourcePolicy",
        ]

        Resource = [
          "*",
        ]
      },
      {
        Sid    = "WafLoggingConfiguration"
        Effect = "Allow"

        Action = [
          "wafv2:DeleteLoggingConfiguration",
          "wafv2:GetLoggingConfiguration",
          "wafv2:PutLoggingConfiguration",
        ]

        Resource = [
          "*",
        ]
      },
      {
        Sid    = "BudgetsManagement"
        Effect = "Allow"

        Action = [
          "budgets:CreateBudget",
          "budgets:DeleteBudget",
          "budgets:ModifyBudget",
          "budgets:ViewBudget",
        ]

        Resource = [
          "arn:aws:budgets::${data.aws_caller_identity.current.account_id}:budget/*",
        ]
      },
      {
        Sid    = "CloudWatchAlarmManagement"
        Effect = "Allow"

        Action = [
          "cloudwatch:DeleteAlarms",
          "cloudwatch:DescribeAlarms",
          "cloudwatch:ListTagsForResource",
          "cloudwatch:PutMetricAlarm",
          "cloudwatch:TagResource",
          "cloudwatch:UntagResource",
        ]

        Resource = [
          "arn:aws:cloudwatch:*:${data.aws_caller_identity.current.account_id}:alarm:${local.role_name_prefix}-*",
        ]
      },
      {
        Sid    = "SnsAlertsManagement"
        Effect = "Allow"

        Action = [
          "sns:CreateTopic",
          "sns:DeleteTopic",
          "sns:GetTopicAttributes",
          "sns:ListTagsForResource",
          "sns:SetTopicAttributes",
          "sns:Subscribe",
          "sns:Unsubscribe",
          "sns:GetSubscriptionAttributes",
          "sns:ListSubscriptionsByTopic",
          "sns:TagResource",
          "sns:UntagResource",
        ]

        Resource = [
          "arn:aws:sns:*:${data.aws_caller_identity.current.account_id}:${local.role_name_prefix}-alerts",
        ]
      },
      {
        # Broad read/list coverage for observability so Terraform refresh does
        # not fail on a missing Get/List/Describe. Mutations remain scoped above.
        Sid    = "ObservabilityRefreshRead"
        Effect = "Allow"

        Action = [
          "budgets:ViewBudget",
          "budgets:DescribeBudget",
          "cloudwatch:DescribeAlarms",
          "cloudwatch:ListTagsForResource",
          "logs:DescribeLogGroups",
          "logs:DescribeResourcePolicies",
          "logs:ListTagsForResource",
          "route53:GetQueryLoggingConfig",
          "route53:ListQueryLoggingConfigs",
          "sns:GetTopicAttributes",
          "sns:ListSubscriptionsByTopic",
          "sns:ListTagsForResource",
          "wafv2:GetLoggingConfiguration",
        ]

        Resource = [
          "*",
        ]
      },
    ]
  })
}

resource "aws_iam_role_policy" "github_plan_permissions" {
  name   = "${local.role_name_prefix}-plan-permissions"
  role   = aws_iam_role.github_plan.name
  policy = local.github_plan_permissions_policy
}

resource "aws_iam_role_policy" "github_deploy_permissions" {
  name   = "${local.role_name_prefix}-deploy-permissions"
  role   = aws_iam_role.github_deploy.name
  policy = local.github_deploy_permissions_policy
}
