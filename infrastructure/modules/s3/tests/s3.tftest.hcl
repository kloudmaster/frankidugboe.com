mock_provider "aws" {}

run "creates_protected_private_origin_bucket" {
  command = plan

  variables {
    bucket_name = "frankidugboe-com-origin-216066926519"
  }

  assert {
    condition     = aws_s3_bucket.this.bucket == "frankidugboe-com-origin-216066926519"
    error_message = "The production origin bucket must use the expected deterministic name."
  }

  assert {
    condition     = aws_s3_bucket.this.force_destroy == false
    error_message = "The origin bucket must not allow forced destruction."
  }

  assert {
    condition     = aws_s3_bucket_ownership_controls.this.rule[0].object_ownership == "BucketOwnerEnforced"
    error_message = "The origin bucket must use BucketOwnerEnforced ownership."
  }

  assert {
    condition = (
      aws_s3_bucket_public_access_block.this.block_public_acls &&
      aws_s3_bucket_public_access_block.this.ignore_public_acls &&
      aws_s3_bucket_public_access_block.this.block_public_policy &&
      aws_s3_bucket_public_access_block.this.restrict_public_buckets
    )
    error_message = "All S3 public-access protections must be enabled."
  }
}

run "enables_versioning_and_encryption" {
  command = plan

  variables {
    bucket_name = "frankidugboe-com-origin-216066926519"
  }

  assert {
    condition     = aws_s3_bucket_versioning.this.versioning_configuration[0].status == "Enabled"
    error_message = "S3 versioning must be enabled."
  }

  assert {
    condition = one(
      one(aws_s3_bucket_server_side_encryption_configuration.this.rule)
      .apply_server_side_encryption_by_default
    ).sse_algorithm == "AES256"

    error_message = "The origin bucket must use AES256 server-side encryption."
  }
}
