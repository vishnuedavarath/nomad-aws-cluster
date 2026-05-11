data "archive_file" "policies" {
  type        = "zip"
  source_dir  = var.policies_dir
  output_path = "${path.module}/.tmp/scaling-policies.zip"
}

locals {
  policy_archive_hash = substr(data.archive_file.policies.output_md5, 0, 12)
  policy_object_key   = "scaling-policies/scaling-policies-${local.policy_archive_hash}.zip"
}

resource "aws_s3_object" "policies" {
  bucket = var.artifacts_bucket_name
  key    = local.policy_object_key
  source = data.archive_file.policies.output_path
  etag   = data.archive_file.policies.output_md5
}
