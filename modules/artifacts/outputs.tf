output "bucket_name" {
  value = aws_s3_bucket.artifacts.bucket
}

output "bucket_arn" {
  value = aws_s3_bucket.artifacts.arn
}

output "autoscaler_binary_url" {
  value       = "s3::https://s3.amazonaws.com/${aws_s3_bucket.artifacts.bucket}/nomad-autoscaler/nomad-autoscaler.zip"
  description = "S3 URL for Nomad artifact stanza (uses go-getter s3:: scheme)"
}
