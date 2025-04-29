resource "aws_eks_node_group" "eks-node" {
  cluster_name    = aws_eks_cluster.eks-cluster.name
  node_group_name = var.node_group
  node_role_arn   = var.lab_role
  subnet_ids      = [for subnet in data.aws_subnet.subnet : subnet.id if subnet.availability_zone != "${var.region}e"]
  disk_size       = 50
  instance_types  = [var.instance_type]

  scaling_config {
    desired_size = 2
    min_size     = 1
    max_size     = 2
  }

  update_config {
    max_unavailable = 1
  }
}
