output "eks_cluster_endpoint" {
  value = aws_eks_cluster.sparkify_eks_cluster.endpoint
}

output "eks_cluster_name" {
  value = aws_eks_cluster.sparkify_eks_cluster.name
}

output "eks_cluster_version" {
  value = aws_eks_cluster.sparkify_eks_cluster.version
}

output "eks_node_group_name" {
  value = aws_eks_node_group.sparkify_node_group.node_group_name
}
