locals {
  github_repository = "${var.github_repository_owner}/${var.github_repository_name}"
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

locals {
  state_bucket_arn = "arn:aws:s3:::${var.state_bucket_name}"
  state_object_arn = "${local.state_bucket_arn}/${var.state_key}"

  site_bucket_arn  = "arn:aws:s3:::${var.site_bucket_name}"
  site_objects_arn = "${local.site_bucket_arn}/*"

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
          "s3:GetBucketLocation",
          "s3:GetBucketOwnershipControls",
          "s3:GetBucketPolicy",
          "s3:GetBucketPublicAccessBlock",
          "s3:GetBucketTagging",
          "s3:GetBucketVersioning",
          "s3:GetEncryptionConfiguration",
          "s3:ListBucket",
        ]

        Resource = [
          local.site_bucket_arn,
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
