variable "cluster_name" {
  description = "EKS 클러스터 이름"
  type        = string
}

variable "cluster_version" {
  description = "EKS Kubernetes 버전"
  type        = string
}

variable "public_subnet_ids" {
  description = "클러스터에 연결할 퍼블릭 서브넷 ID"
  type        = map(string)
}

variable "private_subnet_ids" {
  description = "노드 그룹에 사용할 프라이빗 서브넷 ID"
  type        = map(string)
}

variable "node_group_name" {
  description = "관리형 노드 그룹 이름"
  type        = string
}

variable "node_instance_type" {
  description = "노드 인스턴스 유형"
  type        = string
}

variable "node_desired_size" {
  description = "노드 기본 개수"
  type        = number
}

variable "node_min_size" {
  description = "노드 최소 개수"
  type        = number
}

variable "node_max_size" {
  description = "노드 최대 개수"
  type        = number
}

variable "node_volume_size" {
  description = "노드 루트 디스크 크기 GiB"
  type        = number
}

variable "node_key_name" {
  description = "노드 SSH에 사용할 기존 EC2 키 페어 이름"
  type        = string
}
