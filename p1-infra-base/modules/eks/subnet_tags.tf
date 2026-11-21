resource "aws_ec2_tag" "cluster_public" {
  for_each = var.public_subnet_ids

  resource_id = each.value
  key         = "kubernetes.io/cluster/${var.cluster_name}"
  value       = "shared"
}

resource "aws_ec2_tag" "cluster_private" {
  for_each = var.private_subnet_ids

  resource_id = each.value
  key         = "kubernetes.io/cluster/${var.cluster_name}"
  value       = "shared"
}

resource "aws_ec2_tag" "public_elb" {
  for_each = var.public_subnet_ids

  resource_id = each.value
  key         = "kubernetes.io/role/elb"
  value       = "1"
}

resource "aws_ec2_tag" "private_elb" {
  for_each = var.private_subnet_ids

  resource_id = each.value
  key         = "kubernetes.io/role/internal-elb"
  value       = "1"
}
