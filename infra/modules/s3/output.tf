output "sparkaws_s3_bucket_sparkify_bucket" {
  value = aws_s3_bucket.sparkify_bucket
}

output "sparkaws_s3_bucket_sparkify_bucket_arn" {
  value = aws_s3_bucket.sparkify_bucket.arn
}
