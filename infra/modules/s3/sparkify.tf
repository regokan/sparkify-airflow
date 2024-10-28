resource "aws_s3_bucket" "sparkify_bucket" {
  bucket = "sparkify-airflow-bucket"

  tags = {
    Name        = "sparkify_bucket"
    Project     = "sparkify"
    Owner       = "DataEngg"
    Environment = "Production"
  }
}

resource "aws_s3_bucket_ownership_controls" "sparkify_bucket_ownership_controls" {
  bucket = aws_s3_bucket.sparkify_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "sparkify_bucket_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.sparkify_bucket_ownership_controls]

  bucket = aws_s3_bucket.sparkify_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "sparkify_bucket_versioning" {
  bucket = aws_s3_bucket.sparkify_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "sparkify_bucket_server_side_encryption_configuration" {
  bucket = aws_s3_bucket.sparkify_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "sparkify_bucket_lifecycle_configuration" {
  bucket = aws_s3_bucket.sparkify_bucket.id

  rule {
    id     = "transition-to-glacier"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "GLACIER"
    }
  }
}
