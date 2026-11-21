# Network 기본 설정
region = "ap-northeast-2"
vpc_cidr = "10.0.0.0/16"
vpc_name = "test-vpc"
igw_name = "test-igw"

# Network 서브넷 설정
pub_sub_1_cidr = "10.0.1.0/24"
pub_sub_1_az   = "a"
pub_sub_1_name = "public-subnet-1"

pub_sub_2_cidr = "10.0.2.0/24"
pub_sub_2_az   = "c"
pub_sub_2_name = "public-subnet-2"

pri_sub_1_cidr = "10.0.3.0/24"
pri_sub_1_az   = "a"
pri_sub_1_name = "private-subnet-3"

pri_sub_2_cidr = "10.0.4.0/24"
pri_sub_2_az   = "c"
pri_sub_2_name = "private-subnet-4"

# NAT gateway 및 route table 설정
nat_eip_name          = "nat-eip"
nat_gateway_name      = "my-nat-gateway"
nat_public_subnet_key = "1"

public_route_table_name  = "public-route-table"
private_route_table_name = "private-route-table"

# EKS cluster 설정
cluster_name       = "my-cluster"
cluster_version    = "1.35"
node_group_name    = "worker-nodes"
node_instance_type = "t3.medium"
node_desired_size  = 4
node_min_size      = 2
node_max_size      = 5
node_volume_size   = 20
node_key_name      = "<AWS에 등록한 키페어 이름>"
