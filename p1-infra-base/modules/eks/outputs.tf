output "cluster_name" {
  description = "EKS 클러스터 이름"
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "EKS API 엔드포인트"
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_arn" {
  description = "EKS 클러스터 ARN"
  value       = aws_eks_cluster.this.arn
}

output "node_group_name" {
  description = "관리형 노드 그룹 이름"
  value       = aws_eks_node_group.this.node_group_name
}

output "oidc_provider_arn" {
  description = "클러스터 OIDC 공급자 ARN"
  value       = aws_iam_openid_connect_provider.this.arn
}
