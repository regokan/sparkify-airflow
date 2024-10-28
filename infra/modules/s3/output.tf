output "sparkify_bucket" {
  value = aws_s3_bucket.sparkify_bucket
}

output "sparkify_bucket_arn" {
  value = aws_s3_bucket.sparkify_bucket.arn
}
