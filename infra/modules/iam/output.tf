output "sparkify_redshift_serverless_role_arn" {
  value = aws_iam_role.sparkify_redshift_serverless_role.arn
}

output "sparkify_eks_cluster_role_arn" {
  value = aws_iam_role.sparkify_eks_role.arn
}

output "sparkify_node_group_role_arn" {
  value = aws_iam_role.sparkify_node_group_role.arn
}

output "sparkify_eks_role_policy_attachment" {
  value = aws_iam_role_policy_attachment.sparkify_eks_role_policy_attachment.id
}

output "sparkify_eks_role_vpc_resource_controller_policy_attachment" {
  value = aws_iam_role_policy_attachment.sparkify_eks_role_vpc_resource_controller_policy_attachment.id
}
