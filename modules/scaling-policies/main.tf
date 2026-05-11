locals {
  policy_files = fileset(var.policies_dir, "**/*.hcl")
  # Stable hash based on file contents only (not zip metadata/timestamps)
  policy_content_hash = substr(md5(join("", [
    for f in sort(local.policy_files) : filemd5("${var.policies_dir}/${f}")
  ])), 0, 12)
  policy_object_key = "scaling-policies/scaling-policies-${local.policy_content_hash}.zip"
}

data "archive_file" "policies" {
  type        = "zip"
  source_dir  = var.policies_dir
  output_path = "${path.module}/.tmp/scaling-policies.zip"
}

resource "aws_s3_object" "policies" {
  bucket = var.artifacts_bucket_name
  key    = local.policy_object_key
  source = data.archive_file.policies.output_path
  etag   = local.policy_content_hash
}
