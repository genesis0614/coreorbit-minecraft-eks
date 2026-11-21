resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = var.node_group_name
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = local.node_subnet_ids
  instance_types  = [var.node_instance_type]
  disk_size       = var.node_volume_size

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  remote_access {
    ec2_ssh_key = var.node_key_name
  }

  tags = {
    "k8s.io/cluster-autoscaler/enabled"             = "true"
    "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
  }

  depends_on = [
    aws_iam_role_policy_attachment.node,
    aws_iam_role_policy_attachment.cluster_autoscaler,
    aws_iam_role_policy_attachment.load_balancer_controller,
    aws_eks_addon.vpc_cni
  ]
}
