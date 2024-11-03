resource "aws_eks_cluster" "sparkify_eks_cluster" {
  name     = "sparkify_eks_cluster"
  role_arn = var.sparkify_eks_cluster_role_arn

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  enabled_cluster_log_types     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  bootstrap_self_managed_addons = true

  version = "1.30"

  access_config {
    authentication_mode                         = "CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  depends_on = [
    var.sparkify_eks_role_vpc_resource_controller_policy_attachment,
    var.sparkify_eks_role_policy_attachment
  ]

  tags = {
    Name        = "sparkify_eks_cluster"
    Project     = "sparkify"
    Owner       = "DataEngg"
    Environment = "Production"
  }
}
