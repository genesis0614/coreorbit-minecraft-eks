variable "region" {
  description = "AWS 리전"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
}

variable "vpc_name" {
  description = "VPC 이름 태그"
  type        = string
}

variable "igw_name" {
  description = "인터넷 게이트웨이 이름 태그"
  type        = string
}

variable "nat_eip_name" {
  description = "NAT용 Elastic IP 이름 태그"
  type        = string
}

variable "nat_gateway_name" {
  description = "NAT 게이트웨이 이름 태그"
  type        = string
}

variable "nat_public_subnet_key" {
  description = "NAT 게이트웨이를 둘 퍼블릭 서브넷 번호"
  type        = string
}

variable "public_route_table_name" {
  description = "퍼블릭 라우팅 테이블 이름 태그"
  type        = string
}

variable "private_route_table_name" {
  description = "프라이빗 라우팅 테이블 이름 태그"
  type        = string
}

variable "pub_sub_1_cidr" {
  description = "퍼블릭 서브넷 1 CIDR"
  type        = string
}

variable "pub_sub_1_az" {
  description = "퍼블릭 서브넷 1 가용영역 문자"
  type        = string
}

variable "pub_sub_1_name" {
  description = "퍼블릭 서브넷 1 이름 태그"
  type        = string
}

variable "pub_sub_2_cidr" {
  description = "퍼블릭 서브넷 2 CIDR"
  type        = string
}

variable "pub_sub_2_az" {
  description = "퍼블릭 서브넷 2 가용영역 문자"
  type        = string
}

variable "pub_sub_2_name" {
  description = "퍼블릭 서브넷 2 이름 태그"
  type        = string
}

variable "pri_sub_1_cidr" {
  description = "프라이빗 서브넷 1 CIDR"
  type        = string
}

variable "pri_sub_1_az" {
  description = "프라이빗 서브넷 1 가용영역 문자"
  type        = string
}

variable "pri_sub_1_name" {
  description = "프라이빗 서브넷 1 이름 태그"
  type        = string
}

variable "pri_sub_2_cidr" {
  description = "프라이빗 서브넷 2 CIDR"
  type        = string
}

variable "pri_sub_2_az" {
  description = "프라이빗 서브넷 2 가용영역 문자"
  type        = string
}

variable "pri_sub_2_name" {
  description = "프라이빗 서브넷 2 이름 태그"
  type        = string
}

variable "cluster_name" {
  description = "EKS 클러스터 이름"
  type        = string
}

variable "cluster_version" {
  description = "EKS Kubernetes 버전"
  type        = string
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
