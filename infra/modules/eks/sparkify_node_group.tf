resource "aws_eks_node_group" "sparkify_node_group" {
  cluster_name    = aws_eks_cluster.sparkify_eks_cluster.name
  node_group_name = "sparkify-node-group"
  node_role_arn   = var.sparkify_node_group_role_arn
  subnet_ids      = var.subnet_ids

  scaling_config {
    desired_size = var.node_group_desired_size
    max_size     = var.node_group_max_size
    min_size     = var.node_group_min_size
  }

  depends_on = [aws_eks_cluster.sparkify_eks_cluster]

  ami_type      = "AL2_ARM_64"
  capacity_type = "SPOT"

  disk_size            = 15
  force_update_version = true
  instance_types       = ["t4g.small"]

  tags = {
    Name        = "sparkify_node_group"
    Project     = "sparkify"
    Owner       = "DataEngg"
    Environment = "Production"
  }
}
