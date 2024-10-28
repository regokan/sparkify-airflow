terraform {
  backend "s3" {
    bucket = "sparkify-tf-state"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}

module "s3" {
  source = "./modules/s3"
}

module "iam" {
  source = "./modules/iam"

  sparkify_bucket_arn = module.s3.sparkify_bucket_arn
}


module "redshift" {
  source = "./modules/redshift"

  sparkify_redshift_subnet_ids = [
    aws_subnet.sparkify_subnet1.id,
    aws_subnet.sparkify_subnet2.id,
    aws_subnet.sparkify_subnet3.id
  ]

  sparkify_redshift_security_group_id = aws_security_group.sparkify_redshift_security_group.id

  sparkify_redshift_serverless_role_arn = module.iam.sparkify_redshift_serverless_role_arn

  redshift_namespace_name = var.redshift_namespace_name
  redshift_workgroup_name = var.redshift_workgroup_name
  redshift_db_name        = var.redshift_db_name
  redshift_username       = var.redshift_username
  redshift_password       = var.redshift_password
}
