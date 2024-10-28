output "redshift_endpoint" {
  value       = aws_redshiftserverless_workgroup.sparkify_redshift_workgroup.endpoint
  description = "The Redshift Serverless cluster endpoint"
}
