output "vpc_id" {
  description = "VPC ID"
  value       = module.network.vpc_id
}

output "public_subnet_ids" {
  description = "퍼블릭 서브넷 ID"
  value       = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  description = "프라이빗 서브넷 ID"
  value       = module.network.private_subnet_ids
}

output "internet_gateway_id" {
  description = "인터넷 게이트웨이 ID"
  value       = module.network.internet_gateway_id
}

output "nat_gateway_id" {
  description = "NAT 게이트웨이 ID"
  value       = module.network.nat_gateway_id
}

output "cluster_name" {
  description = "EKS 클러스터 이름"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS API 엔드포인트"
  value       = module.eks.cluster_endpoint
}

output "node_group_name" {
  description = "관리형 노드 그룹 이름"
  value       = module.eks.node_group_name
}
