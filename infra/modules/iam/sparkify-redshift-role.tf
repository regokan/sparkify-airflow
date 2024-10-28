# Create IAM Role for Redshift Serverless
resource "aws_iam_role" "sparkify_redshift_serverless_role" {
  name = "sparkify_redshift_serverless_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = { Service = "redshift-serverless.amazonaws.com" },
        Action    = "sts:AssumeRole"
      },
      {
        Effect    = "Allow",
        Principal = { Service = "redshift.amazonaws.com" },
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "RedshiftServerlessRole"
    Project     = "sparkify"
    Owner       = "DataEngg"
    Environment = "Production"
  }
}

# Attach necessary policies to the IAM Role
resource "aws_iam_role_policy" "redshift_access_policy" {
  name = "RedshiftServerlessAccessPolicy"
  role = aws_iam_role.sparkify_redshift_serverless_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        # S3 Permissions
        Effect = "Allow",
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:ListMultipartUploadParts",
          "s3:AbortMultipartUpload"
        ],
        Resource = [
          "${var.sparkify_bucket_arn}",
          "${var.sparkify_bucket_arn}/*"
        ]
      },
      {
        # Redshift Serverless-specific permissions
        Effect = "Allow",
        Action = [
          "redshift-serverless:GetCredentials",
          "redshift-serverless:CreateWorkgroup",
          "redshift-serverless:ListNamespaces",
          "redshift-serverless:GetWorkgroup",
          "redshift-serverless:GetNamespace"
        ],
        Resource = "*"
      },
      {
        # Additional Redshift permissions for compatibility
        Effect = "Allow",
        Action = [
          "redshift:GetClusterCredentials",
          "redshift:DescribeClusters"
        ],
        Resource = "*"
      },
      {
        # sts:AssumeRole permission for Redshift Serverless to assume this role
        Effect = "Allow",
        Action = "sts:AssumeRole",
        Resource = "${aws_iam_role.sparkify_redshift_serverless_role.arn}"
      }
    ]
  })
}
