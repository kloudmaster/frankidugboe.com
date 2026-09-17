mock_provider "aws" {}

variables {
  github_repository_owner = "kloudmaster"
  github_repository_name  = "frankidugboe.com"

  state_bucket_name           = "frankidugboe-com-terraform-state-216066926519"
  state_key                   = "production/terraform.tfstate"
  site_bucket_name            = "frankidugboe-com-origin-216066926519"
  cloudfront_distribution_arn = "arn:aws:cloudfront::216066926519:distribution/E1AN3BXJ4E5SB7"
  route53_zone_id             = "Z05203182KTV9HKTZIEXD"
  acm_certificate_arn         = "arn:aws:acm:us-east-1:216066926519:certificate/60ae8517-2dd1-4399-b0a2-2f883634cbfc"
}

run "creates_github_actions_oidc_provider" {
  command = plan

  variables {
    github_repository_owner = "kloudmaster"
    github_repository_name  = "frankidugboe.com"
  }

  assert {
    condition     = aws_iam_openid_connect_provider.github.url == "https://token.actions.githubusercontent.com"
    error_message = "GitHub Actions OIDC provider must use token.actions.githubusercontent.com."
  }

  assert {
    condition = contains(
      aws_iam_openid_connect_provider.github.client_id_list,
      "sts.amazonaws.com",
    )
    error_message = "GitHub Actions OIDC audience must include sts.amazonaws.com."
  }
}

run "restricts_github_role_trust" {
  command = apply

  variables {
    github_repository_owner = "kloudmaster"
    github_repository_name  = "frankidugboe.com"
  }

  assert {
    condition = strcontains(
      aws_iam_role.github_plan.assume_role_policy,
      "repo:kloudmaster/frankidugboe.com:pull_request",
    )
    error_message = "Plan role must trust only pull-request GitHub identities for this repository."
  }

  assert {
    condition = strcontains(
      aws_iam_role.github_deploy.assume_role_policy,
      "repo:kloudmaster/frankidugboe.com:environment:production",
    )
    error_message = "Deploy role must trust the protected production GitHub Environment."
  }

  assert {
    condition = !strcontains(
      aws_iam_role.github_deploy.assume_role_policy,
      "repo:kloudmaster/frankidugboe.com:*",
    )
    error_message = "Deploy role trust must not allow every GitHub context in the repository."
  }
}

run "keeps_plan_role_read_only" {
  command = plan

  variables {
    github_repository_owner = "kloudmaster"
    github_repository_name  = "frankidugboe.com"

    state_bucket_name           = "frankidugboe-com-terraform-state-216066926519"
    state_key                   = "production/terraform.tfstate"
    site_bucket_name            = "frankidugboe-com-origin-216066926519"
    cloudfront_distribution_arn = "arn:aws:cloudfront::216066926519:distribution/E1AN3BXJ4E5SB7"
    route53_zone_id             = "Z05203182KTV9HKTZIEXD"
    acm_certificate_arn         = "arn:aws:acm:us-east-1:216066926519:certificate/60ae8517-2dd1-4399-b0a2-2f883634cbfc"
  }

  assert {
    condition = contains(
      flatten([
        for statement in jsondecode(
          aws_iam_role_policy.github_plan_permissions.policy
        ).Statement : statement.Action
      ]),
      "s3:GetObject",
    )

    error_message = "Plan role must be able to read Terraform state."
  }

  assert {
    condition = strcontains(
      aws_iam_role_policy.github_plan_permissions.policy,
      "arn:aws:s3:::frankidugboe-com-terraform-state-216066926519/production/terraform.tfstate",
    )

    error_message = "Plan role state access must include the exact production state object."
  }

  assert {
    condition = !contains(
      flatten([
        for statement in jsondecode(
          aws_iam_role_policy.github_plan_permissions.policy
        ).Statement : statement.Action
      ]),
      "s3:PutObject",
    )

    error_message = "Plan role must not be able to write Terraform state or site objects."
  }

  assert {
    condition = !contains(
      flatten([
        for statement in jsondecode(
          aws_iam_role_policy.github_plan_permissions.policy
        ).Statement : statement.Action
      ]),
      "route53:ChangeResourceRecordSets",
    )

    error_message = "Plan role must not be able to modify Route 53."
  }

  assert {
    condition = !contains(
      flatten([
        for statement in jsondecode(
          aws_iam_role_policy.github_plan_permissions.policy
        ).Statement : statement.Action
      ]),
      "cloudfront:CreateInvalidation",
    )

    error_message = "Plan role must not be able to mutate CloudFront."
  }
}

run "scopes_deploy_role_without_iam_self_modification" {
  command = plan

  variables {
    github_repository_owner = "kloudmaster"
    github_repository_name  = "frankidugboe.com"

    state_bucket_name           = "frankidugboe-com-terraform-state-216066926519"
    state_key                   = "production/terraform.tfstate"
    site_bucket_name            = "frankidugboe-com-origin-216066926519"
    cloudfront_distribution_arn = "arn:aws:cloudfront::216066926519:distribution/E1AN3BXJ4E5SB7"
    route53_zone_id             = "Z05203182KTV9HKTZIEXD"
    acm_certificate_arn         = "arn:aws:acm:us-east-1:216066926519:certificate/60ae8517-2dd1-4399-b0a2-2f883634cbfc"
  }

  assert {
    condition = contains(
      flatten([
        for statement in jsondecode(
          aws_iam_role_policy.github_deploy_permissions.policy
        ).Statement : statement.Action
      ]),
      "s3:PutObject",
    )

    error_message = "Deploy role must be able to upload the built site."
  }

  assert {
    condition = contains(
      flatten([
        for statement in jsondecode(
          aws_iam_role_policy.github_deploy_permissions.policy
        ).Statement : statement.Action
      ]),
      "s3:DeleteObject",
    )

    error_message = "Deploy role must support S3 sync --delete."
  }

  assert {
    condition = contains(
      flatten([
        for statement in jsondecode(
          aws_iam_role_policy.github_deploy_permissions.policy
        ).Statement : statement.Action
      ]),
      "cloudfront:CreateInvalidation",
    )

    error_message = "Deploy role must be able to invalidate the portfolio distribution."
  }

  assert {
    condition = contains(
      flatten([
        for statement in jsondecode(
          aws_iam_role_policy.github_deploy_permissions.policy
        ).Statement : statement.Action
      ]),
      "route53:ChangeResourceRecordSets",
    )

    error_message = "Deploy role must support Terraform-managed portfolio DNS changes."
  }

  assert {
    condition = strcontains(
      aws_iam_role_policy.github_deploy_permissions.policy,
      "arn:aws:cloudfront::216066926519:distribution/E1AN3BXJ4E5SB7",
    )

    error_message = "Deploy permissions must reference the portfolio CloudFront distribution."
  }

  assert {
    condition = strcontains(
      aws_iam_role_policy.github_deploy_permissions.policy,
      "arn:aws:s3:::frankidugboe-com-origin-216066926519/*",
    )

    error_message = "Deploy object permissions must be scoped to the portfolio origin bucket."
  }

  assert {
    condition = strcontains(
      aws_iam_role_policy.github_deploy_permissions.policy,
      "arn:aws:route53:::hostedzone/Z05203182KTV9HKTZIEXD",
    )

    error_message = "Route 53 write access must be scoped to the portfolio hosted zone."
  }

  assert {
    condition = !contains(
      flatten([
        for statement in jsondecode(
          aws_iam_role_policy.github_deploy_permissions.policy
        ).Statement : statement.Action
      ]),
      "iam:*",
    )

    error_message = "Deploy role must never receive iam:*."
  }

  assert {
    condition = alltrue([
      for action in flatten([
        for statement in jsondecode(
          aws_iam_role_policy.github_deploy_permissions.policy
        ).Statement : statement.Action
      ]) :
      !startswith(action, "iam:Create") &&
      !startswith(action, "iam:Put") &&
      !startswith(action, "iam:Attach") &&
      !startswith(action, "iam:Update") &&
      !startswith(action, "iam:Delete") &&
      !startswith(action, "iam:Set")
    ])

    error_message = "Deploy role must not be able to create, modify, or delete IAM resources."
  }
}

run "exports_github_role_arns" {
  command = plan

  assert {
    condition     = output.github_plan_role_arn == aws_iam_role.github_plan.arn
    error_message = "github_plan_role_arn must expose the GitHub plan role ARN."
  }

  assert {
    condition     = output.github_deploy_role_arn == aws_iam_role.github_deploy.arn
    error_message = "github_deploy_role_arn must expose the GitHub deploy role ARN."
  }
}

run "supports_non_iam_terraform_apply" {
  command = plan

  assert {
    condition = alltrue([
      for required_action in [
        "cloudfront:CreateDistribution",
        "cloudfront:CreateDistributionWithTags",
        "cloudfront:CreateFunction",
        "cloudfront:UpdateFunction",
        "cloudfront:PublishFunction",
        "cloudfront:DeleteFunction",
        "cloudfront:CreateOriginAccessControl",
        "cloudfront:UpdateOriginAccessControl",
        "cloudfront:DeleteOriginAccessControl",
        "acm:RequestCertificate",
        "acm:AddTagsToCertificate",
        "acm:RemoveTagsFromCertificate",
        "acm:DeleteCertificate",
        "route53:CreateHostedZone",
        "route53:DeleteHostedZone",
        "route53:GetChange",
        "route53:ChangeTagsForResource",
        "s3:DeleteBucketOwnershipControls",
        "s3:DeleteBucketPublicAccessBlock",
        "s3:DeleteBucketEncryption",
      ] :
      contains(
        flatten([
          for statement in jsondecode(
            aws_iam_role_policy.github_deploy_permissions.policy
          ).Statement : statement.Action
        ]),
        required_action,
      )
    ])

    error_message = "Deploy role must support the complete non-IAM Terraform lifecycle used by the portfolio."
  }

  assert {
    condition = alltrue([
      for action in flatten([
        for statement in jsondecode(
          aws_iam_role_policy.github_deploy_permissions.policy
        ).Statement : statement.Action
      ]) :
      !startswith(action, "iam:Create") &&
      !startswith(action, "iam:Put") &&
      !startswith(action, "iam:Attach") &&
      !startswith(action, "iam:Update") &&
      !startswith(action, "iam:Delete") &&
      !startswith(action, "iam:Set")
    ])

    error_message = "Full Terraform deployment permissions must not introduce IAM self-modification."
  }
}
