data "archive_file" "policies" {
  type        = "zip"
  source_dir  = var.policies_dir
  output_path = "${path.module}/.tmp/scaling-policies.zip"
}

resource "aws_s3_object" "policies" {
  bucket = var.artifacts_bucket_name
  key    = "scaling-policies/scaling-policies.zip"
  source = data.archive_file.policies.output_path
  etag   = data.archive_file.policies.output_md5
}
