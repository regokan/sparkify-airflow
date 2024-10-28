variable "sparkify_redshift_serverless_role_arn" {
  description = "The ARN of the Sparkify Redshift Serverless role"
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

variable "sparkify_redshift_subnet_ids" {
  description = "The subnet IDs for the Sparkify Redshift workgroup"
  type        = list(string)
}

variable "sparkify_redshift_security_group_id" {
  description = "The security group ID for the Sparkify Redshift workgroup"
  type        = string
}
