locals {
  cluster_subnet_ids = concat(values(var.public_subnet_ids), values(var.private_subnet_ids))
  node_subnet_ids    = values(var.private_subnet_ids)
  oidc_issuer        = aws_eks_cluster.this.identity[0].oidc[0].issuer
  oidc_host          = replace(local.oidc_issuer, "https://", "")
}
