output "policies_s3_url" {
  value       = "s3::https://s3.amazonaws.com/${var.artifacts_bucket_name}/${aws_s3_object.policies.key}"
  description = "S3 URL for the scaling policies zip (go-getter format)"
}

output "policies_hash" {
  value       = data.archive_file.policies.output_md5
  description = "MD5 hash of the policies zip, changes when any policy file is added/modified/removed"
}
