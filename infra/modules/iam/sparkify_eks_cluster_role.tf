resource "aws_iam_role" "sparkify_eks_role" {
  name = "sparkify_eks_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })

  tags = {
    Name        = "sparkify_eks_role"
    Project     = "sparkify"
    Owner       = "DataEngg"
    Environment = "Production"
  }
}

resource "aws_iam_role_policy_attachment" "sparkify_eks_role_policy_attachment" {
  role       = aws_iam_role.sparkify_eks_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "sparkify_eks_role_vpc_resource_controller_policy_attachment" {
  role       = aws_iam_role.sparkify_eks_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}
