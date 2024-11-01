# AWS Access Key
variable "aws_access_key" {
  description = "AWS Access Key"
  type        = string
}

# AWS Secret Key
variable "aws_secret_key" {
  description = "AWS Secret Key"
  type        = string
}

# AWS Region
variable "region" {
  description = "AWS Region"
  default     = "us-east-1"
  type        = string
}

variable "redshift_namespace_name" {
  description = "The name of the Redshift Serverless namespace"
  type        = string
}

variable "redshift_workgroup_name" {
  description = "The name of the Redshift Serverless workgroup"
  type        = string
}

variable "redshift_db_name" {
  description = "The name of the default database in Redshift"
  type        = string
  default     = "dev"
}

variable "redshift_username" {
  description = "Username for Redshift database access"
  type        = string
}

variable "redshift_password" {
  description = "Password for Redshift database access"
  type        = string
  sensitive   = true
}
