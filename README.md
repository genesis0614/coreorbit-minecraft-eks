# CoreOrbit: EKS 기반 Minecraft 플랫폼

Terraform으로 AWS 네트워크와 EKS 클러스터를 만들고, Amazon EFS를 공유 저장소로 사용하는 Minecraft 서버 두 대와 BungeeCord 프록시, ELK 로그 분석 스택을 Kubernetes에 배포하는 프로젝트입니다.

실제 AWS 배포 전에는 계정 권한, 리전, 비용, 네트워크 및 아래의 LoadBalancer 검토사항을 확인하세요.



## 주요 구성

- **인프라**: Terraform 모듈로 VPC, 서브넷, IGW, NAT Gateway, 라우팅 테이블, EKS 및 관리형 노드 그룹 생성
- **게임 서비스**: Minecraft 서버 두 대와 BungeeCord Helm 차트
- **공유 저장소**: Amazon EFS CSI Driver, StorageClass, PVC
- **로그 분석**: Filebeat → Logstash → Elasticsearch → Kibana
- **발표 및 아키텍처 자료**: `p0-ppt-work`


## 아키텍처 개요

```text
AWS VPC (public/private subnets, IGW, NAT, routes)
└── Amazon EKS
        ├── Managed node group (private subnets)
        ├── Minecraft server 1 ─┐
        ├── Minecraft server 2 ─┴── BungeeCord Helm release
        ├── Amazon EFS CSI Driver ─── EFS PVC (Minecraft logs)
        └── ELK (namespace: elk)
                ├── Filebeat (namespace: default; reads shared EFS logs)
                ├── Logstash
                ├── Elasticsearch
                └── Kibana
```


## 저장소 구조

```text
.
├── p1-infra-base/
│   ├── infra/                    # Terraform root module과 변수
│   └── modules/
│       ├── network/              # VPC, subnet, IGW, NAT, routes
│       └── eks/                  # EKS, IAM, node group, addons
├── p2-game-server/              # EFS 설정, Minecraft YAML, BungeeCord Helm chart
├── p3-log-analysis-ELK/          # Elasticsearch, Filebeat, Logstash, Kibana
└── p4-monitoring-Pro-Gra-Sla/    # 현재 비어 있음
```


## 사전 준비

### 도구와 계정

- AWS 계정과 필요한 IAM 권한, AWS CLI
- Terraform 1.5 이상
- `kubectl`
- Helm
- `eksctl`은 아래 EFS CSI IAM 서비스계정을 만들 때만 사용합니다. **EKS 클러스터 생성에는 사용하지 않습니다.**
- Windows에서는 아래 Bash 명령을 WSL 또는 Git Bash에서 실행하세요.

AWS 프로필을 설정하고 배포할 계정과 리전을 확인합니다.

```bash
aws configure
aws sts get-caller-identity
```

### EC2 키 페어와 `terraform.tfvars`

Terraform의 EKS 관리형 노드 그룹은 `remote_access.ec2_ssh_key`에 연결할 기존 EC2 키 페어 이름을 요구합니다. AWS 콘솔의 EC2 **Key pairs**에서 배포 리전과 같은 리전에 키 페어를 생성하고, 다운로드한 개인 키 파일은 안전한 로컬 위치에 보관하세요.

`p1-infra-base/infra/terraform.tfvars`의 `node_key_name`에는 개인 키 파일 경로나 키 내용이 아니라 AWS에 등록된 **키 페어 이름**을 입력합니다.

```hcl
node_key_name = "<AWS에-등록한-키-페어-이름>"
```

`p1-infra-base/infra/variables.tf`의 필수 값은 모두 설정해야 합니다. 네트워크 변수에는 리전, VPC CIDR, 두 개의 public/private subnet CIDR·AZ suffix·이름, NAT 배치용 public subnet key와 리소스 이름이 포함됩니다. EKS 변수에는 cluster name/version, node group name, instance type, desired/min/max 개수, node volume 크기와 위의 `node_key_name`이 포함됩니다.

`terraform.tfvars`, Terraform state, `.pem`/`.ppk` 개인 키, kubeconfig 및 실제 비밀번호는 공개 저장소에 커밋하지 마세요. README에는 비밀값을 넣지 말고 로컬 변수 파일에서만 관리하세요.


## 배포 흐름

모든 명령은 저장소 루트에서 시작한다고 가정합니다. 단계마다 성공 여부를 확인한 뒤 다음 단계로 진행하세요.

### 1. Terraform으로 네트워크와 EKS 생성

`p1-infra-base/infra`의 root module이 `modules/network`와 `modules/eks`를 함께 호출합니다. 따라서 Terraform 적용 한 번으로 VPC 및 public/private subnets, IGW, NAT/EIP, route tables와 EKS control plane 및 private-subnet managed node group이 생성됩니다. EKS 모듈은 OIDC provider, access entry, IAM 역할/정책, subnet tags 및 VPC CNI, CoreDNS, kube-proxy addons도 구성합니다.

```bash
cd p1-infra-base/infra
terraform init
terraform validate
terraform plan
```

`terraform plan`에서 생성·변경·삭제될 리소스와 예상 AWS 비용을 확인합니다. 기존 환경이 의도치 않게 삭제되거나 대체될 것 같으면 진행하지 말고 변수와 state를 확인하세요. 내용이 맞을 때만 적용합니다.

```bash
terraform apply
```

Terraform이 출력한 클러스터 이름과 `terraform.tfvars`에 설정한 리전으로 kubeconfig를 갱신합니다.

```bash
AWS_REGION="ap-northeast-2" # terraform.tfvars의 region 값으로 변경
CLUSTER_NAME=$(terraform -chdir=p1-infra-base/infra output -raw cluster_name)
aws eks --region "$AWS_REGION" update-kubeconfig --name "$CLUSTER_NAME"
kubectl get nodes -o wide
```

모든 노드가 `Ready`인지 확인합니다. Terraform은 **EFS 파일시스템 자체는 만들지 않습니다.** EFS 생성은 3단계에서 수행합니다.

### 2. EFS CSI Driver의 IAM 서비스계정 및 드라이버

EFS CSI Driver용 정책을 생성하고 ARN을 확인합니다. 정책이 이미 있다면 중복 생성 대신 기존 ARN을 사용하세요.

```bash
POLICY_ARN=$(aws iam create-policy \
    --policy-name AmazonEFSCSIPolicy \
    --policy-document file://p2-game-server/02-efs-csi-iam-policy.json \
    --query Policy.Arn \
    --output text)
```

`eksctl create iamserviceaccount`는 클러스터를 만드는 명령이 아닙니다. 기존 EKS의 OIDC와 IAM을 사용해 EFS CSI Controller 서비스계정을 연결하는 단계입니다.

```bash
eksctl create iamserviceaccount \
    --cluster "$CLUSTER_NAME" \
    --namespace kube-system \
    --name efs-csi-controller-sa \
    --attach-policy-arn "$POLICY_ARN" \
    --approve \
    --region "$AWS_REGION"
```

Helm으로 CSI Driver를 설치합니다. 아래 예시는 기존 workflow의 ap-northeast-2 이미지 저장소입니다. 다른 리전이라면 해당 리전의 ECR repository 주소로 바꿉니다.

```bash
helm repo add aws-efs-csi-driver https://kubernetes-sigs.github.io/aws-efs-csi-driver/
helm repo update
helm upgrade --install aws-efs-csi-driver aws-efs-csi-driver/aws-efs-csi-driver \
    --namespace kube-system \
    --set image.repository=602401143452.dkr.ecr.ap-northeast-2.amazonaws.com/eks/aws-efs-csi-driver \
    --set controller.serviceAccount.create=false \
    --set controller.serviceAccount.name=efs-csi-controller-sa
```

### 3. Amazon EFS, mount targets, StorageClass 및 PVC

Terraform 코드에는 EFS resource가 없으므로 AWS CLI로 생성합니다. 같은 계정/VPC에서 보안 그룹이나 EFS를 이미 만들었다면 재생성하지 말고 기존 ID를 사용하세요.

VPC ID와 CIDR을 조회하고, VPC CIDR에서만 NFS TCP 2049를 허용하는 EFS 보안 그룹을 만듭니다.

```bash
AWS_REGION="ap-northeast-2" # terraform.tfvars의 region 값으로 변경
CLUSTER_NAME=$(terraform -chdir=p1-infra-base/infra output -raw cluster_name)

VPC_ID=$(aws eks describe-cluster \
    --name "$CLUSTER_NAME" --region "$AWS_REGION" \
    --query 'cluster.resourcesVpcConfig.vpcId' --output text)
VPC_CIDR=$(aws ec2 describe-vpcs \
    --vpc-ids "$VPC_ID" --region "$AWS_REGION" \
    --query 'Vpcs[0].CidrBlock' --output text)

EFS_SG_ID=$(aws ec2 create-security-group \
    --group-name coreorbit-efs-sg \
    --description "EFS mount target access from the EKS VPC" \
    --vpc-id "$VPC_ID" --region "$AWS_REGION" \
    --query GroupId --output text)

aws ec2 authorize-security-group-ingress \
    --group-id "$EFS_SG_ID" --protocol tcp --port 2049 \
    --cidr "$VPC_CIDR" --region "$AWS_REGION"
```

EFS를 만들고 `FileSystemId`를 기록합니다.

```bash
EFS_ID=$(aws efs create-file-system \
    --region "$AWS_REGION" \
    --performance-mode generalPurpose \
    --query FileSystemId --output text)
aws efs wait file-system-available --file-system-id "$EFS_ID" --region "$AWS_REGION"
echo "$EFS_ID"
```

EKS 노드가 있는 private subnet과 AZ를 조회한 뒤, **노드가 사용하는 각 AZ마다 하나씩** mount target을 생성합니다.

```bash
aws ec2 describe-subnets \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --query 'Subnets[*].{SubnetId:SubnetId,AZ:AvailabilityZone,CIDR:CidrBlock}' \
    --output table --region "$AWS_REGION"

read -r -p "Private subnet ID in the first node AZ: " PRIVATE_SUBNET_1
read -r -p "Private subnet ID in the second node AZ: " PRIVATE_SUBNET_2

aws efs create-mount-target --file-system-id "$EFS_ID" \
    --subnet-id "$PRIVATE_SUBNET_1" --security-groups "$EFS_SG_ID" --region "$AWS_REGION"
aws efs create-mount-target --file-system-id "$EFS_ID" \
    --subnet-id "$PRIVATE_SUBNET_2" --security-groups "$EFS_SG_ID" --region "$AWS_REGION"
```

`p2-game-server/03-storageclass.yaml`의 `fileSystemId`를 방금 만든 ID로 수정하고 적용합니다. 파일에 남아 있는 과거 ID를 그대로 쓰지 마세요.

```bash
kubectl apply -f p2-game-server/03-storageclass.yaml
kubectl apply -f p2-game-server/04-pvc.yaml
kubectl get storageclass,pv,pvc
kubectl get pods -n kube-system
```

PVC가 `Bound`인지 확인합니다. CSI Controller의 실제 Pod 이름을 확인한 뒤 필요하면 로그를 봅니다.

```bash
kubectl get pods -n kube-system
CSI_POD=$(kubectl get pods -n kube-system -o name | grep efs-csi-controller | head -n 1)
kubectl logs "$CSI_POD" -n kube-system -c csi-provisioner --tail=20
```

### 4. Minecraft 서버 배포

두 Deployment가 같은 `efs-claim` PVC를 사용합니다.

```bash
kubectl apply -f p2-game-server/05-minecraft-server-1.yaml
kubectl apply -f p2-game-server/06-minecraft-server-2.yaml
kubectl get pods,svc -n default -o wide
```

Pod가 `Running`인지, 서비스가 NodePort `30001`과 `30002`를 사용하는지 확인합니다.

### 5. BungeeCord Helm 차트 배포

현재 P2의 주 배포 방식은 Helm입니다. 차트가 ConfigMap, Deployment, Service를 생성하므로 과거 `kubectl create configmap` 또는 `kubectl apply -f bungeecode.yaml`을 함께 실행하지 않습니다.

```bash
helm lint p2-game-server/07-helm-bungeecord
helm upgrade --install bungeecord p2-game-server/07-helm-bungeecord --namespace default
kubectl rollout status deployment/bungeecord -n default
kubectl get pods,svc -n default
```

`values.yaml`의 `lobby`와 `game` 주소가 각각 `minecraft-service-1:25565`, `minecraft-service-2:25565`를 가리키는지 확인합니다.

### 6. ELK 로그 분석 배포

ELK 리소스는 `elk` namespace, Filebeat는 `default` namespace에 배포됩니다. 과거 ELB hostname은 재사용하지 말고 같은 클러스터의 Kubernetes 서비스 DNS를 사용하도록 ConfigMap을 확인합니다.

#### Elasticsearch

현재 manifest 순서대로 적용하고 StatefulSet이 준비됐는지 기다립니다.

```bash
kubectl apply -f p3-log-analysis-ELK/01-elasticsearch/01-elk-namespace.yaml
kubectl apply -f p3-log-analysis-ELK/01-elasticsearch/02-elasticsearch-configmap.yaml
kubectl apply -f p3-log-analysis-ELK/01-elasticsearch/03-elasticsearch-persistentvolume.yaml
kubectl apply -f p3-log-analysis-ELK/01-elasticsearch/04-elasticsearch-statefulset.yaml
kubectl apply -f p3-log-analysis-ELK/01-elasticsearch/05-elasticsearch-service.yaml
kubectl rollout status statefulset/elasticsearch-node -n elk
kubectl get pods,svc -n elk
```

내부 Elasticsearch 서비스 DNS는 `elasticsearch.elk.svc.cluster.local:9200`입니다. `elasticsearch-nodeport`라는 서비스 이름이지만 현재 manifest의 `type`은 `LoadBalancer`입니다.

#### Logstash

`p3-log-analysis-ELK/03-logstash/01-logstash-configmap.yaml`의 Elasticsearch 주소를 내부 서비스 DNS로 맞추고, 인증 설정이 Elasticsearch와 일치하는지 확인합니다. 비밀번호를 ConfigMap/README에 평문으로 두지 말고 Kubernetes Secret 사용을 검토하세요.

```bash
kubectl apply -f p3-log-analysis-ELK/03-logstash/01-logstash-configmap.yaml
kubectl apply -f p3-log-analysis-ELK/03-logstash/02-logstash-deployment.yaml
kubectl apply -f p3-log-analysis-ELK/03-logstash/03-logstash-service.yaml
kubectl get pods,svc -n elk
```

#### Filebeat

`p3-log-analysis-ELK/02-filebeat/01-filebeat-configmap.yaml`의 Logstash 주소를 `logstash.elk.svc.cluster.local:5000`으로 지정합니다. Minecraft가 PVC에 쓰는 로그 형식과 `filebeat.inputs.paths`가 일치하는지도 확인합니다.

```bash
kubectl apply -f p3-log-analysis-ELK/02-filebeat/01-filebeat-configmap.yaml
kubectl apply -f p3-log-analysis-ELK/02-filebeat/02-filebeat-deployment.yaml
kubectl get pods -n default
```

#### Kibana

Kibana ConfigMap의 `elasticsearch.hosts`와 Deployment의 `ELASTICSEARCH_HOSTS`가 같은 내부 Elasticsearch 주소를 사용하도록 맞춥니다.

```bash
kubectl apply -f p3-log-analysis-ELK/04-kibana/01-kibana-configmap.yaml
kubectl apply -f p3-log-analysis-ELK/04-kibana/02-kibana-deployment.yaml
kubectl apply -f p3-log-analysis-ELK/04-kibana/03-kibana-service.yaml
kubectl get pods,svc -n elk
```

### 7. 동작 확인

```bash
kubectl get nodes
kubectl get pods,svc -A
kubectl logs deployment/filebeat -n default
kubectl logs deployment/logstash -n elk
```

Elasticsearch Pod 이름을 조회한 뒤 로컬에서 API를 확인합니다.

```bash
kubectl get pods -n elk
kubectl port-forward pod/<elasticsearch-pod-name> 9200:9200 -n elk
```

포트포워딩이 유지되는 동안 다른 터미널에서 실행합니다.

```bash
curl -sS "http://localhost:9200/_cluster/health?pretty"
curl -sS "http://localhost:9200/_cat/indices?v"
```

Kibana는 `kubectl get svc kibana -n elk`로 서비스 포트를 확인합니다. 과거 ELB 주소나 Pod 이름을 재사용하지 마세요.



## 배포 전 확인이 필요한 구성

- BungeeCord, Elasticsearch, Logstash, Kibana 서비스 중 일부 manifest는 `type: LoadBalancer`입니다. 이 설정은 AWS Load Balancer 생성을 요청합니다. Terraform은 관련 IAM policy와 subnet tag를 설정하지만 AWS Load Balancer Controller 자체를 설치하지 않으므로, 외부 LB 배포는 현재 저장소만으로 검증되지 않았습니다. 선택지와 확인사항은 `workflow-review-candidates.txt`를 보세요.
- Elasticsearch는 현재 `hostPath` 기반 PV와 단일 replica입니다. 노드 교체 시 데이터 지속성을 보장하는 운영용 저장소 구성이 아닙니다.
- ELK manifest의 Elasticsearch 주소/인증 설정은 서로 일치하도록 실제 환경에서 조정해야 합니다. 현재 확인되지 않은 endpoint/credential을 그대로 복사하지 마세요.
- `p4-monitoring-Pro-Gra-Sla/`는 비어 있어 모니터링 배포 절차는 포함하지 않았습니다.



## 정리 파일

- `workflow-review-candidates.txt`: 배포 전에 프로젝트 소유자가 결정해야 할 내용
- `workflow-delete.txt`: 기존 메모에서 현재 Helm/Terraform 흐름에 중복되는 절차를 별도 보관
- `workflow-delete-eks.txt`: 별도 검토를 위해 분리한 과거 절차



## 공개 저장소에 올리기 전

- `terraform.tfvars`, Terraform state, `.pem`/`.ppk`, kubeconfig를 확인하고 공개 저장소에 커밋하지 마세요.
- IAM 정책, ELK 인증 설정, 계정/리소스 ID, 외부 주소가 불필요하게 노출되는지 확인하세요.
- 루트 프로젝트의 라이선스와 실제 AWS 배포 검증 여부는 별도로 결정하세요.
