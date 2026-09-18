mock_provider "aws" {
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  mock_data "aws_canonical_user_id" {
    defaults = {
      id = "mockcanonicaluserid0000000000000000000000000000000000000000000000"
    }
  }
}

run "provisions_governed_log_bucket" {
  command = plan

  variables {
    bucket_name = "frankidugboe-com-logs-216066926519"
  }

  assert {
    condition     = aws_s3_bucket_ownership_controls.logs.rule[0].object_ownership == "BucketOwnerPreferred"
    error_message = "The log bucket must enable ACLs (BucketOwnerPreferred) for log delivery."
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.logs.block_public_acls == true
    error_message = "The log bucket must block public ACLs."
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.logs.restrict_public_buckets == true
    error_message = "The log bucket must restrict public access."
  }

  assert {
    condition     = aws_s3_bucket_lifecycle_configuration.logs.rule[0].expiration[0].days == 90
    error_message = "Delivered logs must expire to control cost."
  }

  assert {
    condition = anytrue([
      for g in aws_s3_bucket_acl.logs.access_control_policy[0].grant :
      try(g.grantee[0].uri, "") == "http://acs.amazonaws.com/groups/s3/LogDelivery"
    ])
    error_message = "The log-delivery group must be granted write access."
  }
}
