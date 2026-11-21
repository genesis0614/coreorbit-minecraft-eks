variable "region" {
  description = "AWS 리전. 가용영역 이름의 앞부분으로 쓴다."
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

variable "public_subnets" {
  description = "퍼블릭 서브넷. az는 리전 뒤에 붙는 가용영역 문자다."
  type = map(object({
    cidr = string
    az   = string
    name = string
  }))
}

variable "private_subnets" {
  description = "프라이빗 서브넷. az는 리전 뒤에 붙는 가용영역 문자다."
  type = map(object({
    cidr = string
    az   = string
    name = string
  }))
}
