# Create a Redshift Serverless Namespace
resource "aws_redshiftserverless_namespace" "sparkify_redshift_namespace" {
  namespace_name      = var.redshift_namespace_name
  db_name             = var.redshift_db_name
  admin_username      = var.redshift_username
  admin_user_password = var.redshift_password
  iam_roles           = [var.sparkify_redshift_serverless_role_arn]

  tags = {
    Name        = "SparkifyRedshiftNamespace"
    Project     = "Sparkify"
    Owner       = "DataEngg"
    Environment = "Production"
  }
}

# Create a Redshift Serverless Workgroup
resource "aws_redshiftserverless_workgroup" "sparkify_redshift_workgroup" {
  workgroup_name = var.redshift_workgroup_name
  namespace_name = aws_redshiftserverless_namespace.sparkify_redshift_namespace.namespace_name

  base_capacity = 32 # Capacity in Redshift Processing Units (RPUs)

  subnet_ids          = var.sparkify_redshift_subnet_ids
  security_group_ids  = [var.sparkify_redshift_security_group_id]
  publicly_accessible = true

  tags = {
    Name        = "SparkifyRedshiftWorkgroup"
    Project     = "Sparkify"
    Owner       = "DataEngg"
    Environment = "Production"
  }
}
