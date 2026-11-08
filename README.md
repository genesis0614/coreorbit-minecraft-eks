# CoreOrbit: EKS 기반 Minecraft 서버 플랫폼

AWS EKS에 Minecraft 서버와 BungeeCord 프록시를 배포하고, EFS 기반 저장소와 ELK 로그 수집 구성을 실험한 프로젝트입니다. Terraform, Kubernetes 매니페스트, Helm 차트와 작업 기록을 포함합니다.

> 이 저장소에는 여러 단계의 실험 및 버전별 파일이 함께 있습니다. 아래 절차는 현재 파일 구성을 기준으로 정리한 안내이며, 실제 AWS 계정에 배포하기 전에 변수와 리소스 구성을 확인하세요.

## 주요 구성

- **인프라**: Terraform 모듈로 AWS 네트워크와 EKS 클러스터 구성
- **게임 서버**: Kubernetes에 Minecraft 서버 두 개와 BungeeCord 프록시 배포
- **공유 스토리지**: Amazon EFS CSI Driver, StorageClass 및 PVC 구성
- **로그 분석**: Filebeat, Logstash, Elasticsearch, Kibana 매니페스트
- **모니터링**: 모니터링 관련 자료를 정리하기 위한 디렉터리

## 아키텍처 개요

```text
AWS VPC
└── Amazon EKS
    ├── Minecraft Server 1 ─┐
    ├── Minecraft Server 2 ─┴── BungeeCord
    ├── EFS CSI Driver ──────── Amazon EFS (PV/PVC)
    └── ELK Stack
        ├── Filebeat
        ├── Logstash
        ├── Elasticsearch
        └── Kibana
```

## 저장소 구조

```text
.
├── P0.PPT 작업/                 # 아키텍처 다이어그램 및 발표 자료
├── P1.Infra-Base/               # Terraform 기반 네트워크 및 EKS 인프라
│   ├── infra/
│   └── modules/
├── P2.Game-Server/              # EFS, Minecraft, BungeeCord 배포 파일
├── P3.Analysis-ELK/             # Elasticsearch, Filebeat, Logstash, Kibana
├── P4.Monitoring-Pro,Gra,Sla/   # 모니터링 자료 디렉터리
├── Project_CoreOrbit_Kube_terraform-V*/  # 이전 Terraform/Kubernetes 작업 버전
├── Project CoreOrbit_EKS_terraform-V7/   # 이전 통합 작업 버전
├── eks/, minecrafthelm/         # 예제 및 별도 Helm/Kubernetes 파일
├── 프로젝트 워크플로우.txt       # 기존 작업 절차 메모
└── README.md
```

## 사전 준비

배포 방식과 사용하는 매니페스트에 따라 다음 도구가 필요합니다.

- AWS CLI 및 배포 권한이 있는 AWS 계정
- Terraform
- `kubectl`
- `eksctl` (수동 EKS 구성 경로를 사용할 경우)
- Helm (EFS CSI Driver 또는 BungeeCord Helm 차트를 설치할 경우)

AWS 인증 정보는 로컬 환경에서 설정합니다.

```bash
aws configure
```

## 배포 흐름

### 1. 인프라 구성

Terraform 코드가 있는 디렉터리에서 인프라를 초기화하고 변경 사항을 확인한 후 적용합니다.

```bash
cd P1.Infra-Base/infra
terraform init
terraform plan
terraform apply
```

클러스터 이름, AWS 리전, 네트워크 및 노드 그룹 설정은 Terraform 변수 파일과 변수 정의를 확인하세요.

> 작업 기록에는 `eksctl create cluster`를 이용한 수동 생성 절차도 있습니다. Terraform 구성 역시 EKS를 생성하므로 두 방법을 같은 리소스에 함께 적용하지 마세요. 사용할 한 가지 경로를 정하고 기존 리소스와 상태를 먼저 확인해야 합니다.

### 2. kubectl 연결

실제 리전과 클러스터 이름으로 값을 바꿔 kubeconfig를 설정하고 연결을 확인합니다.

```bash
aws eks --region <region> update-kubeconfig --name <cluster-name>
kubectl get nodes
```

### 3. EFS 및 영구 볼륨 구성

EFS CSI Driver에 필요한 IAM/OIDC 권한을 준비하고, 클러스터 노드가 있는 네트워크에 EFS mount target을 구성합니다. 이후 `P2.Game-Server/`의 StorageClass와 PVC 매니페스트를 실제 EFS 파일 시스템 ID에 맞게 확인한 뒤 적용합니다.

```bash
kubectl apply -f P2.Game-Server/3.storageclass.yaml
kubectl apply -f P2.Game-Server/4.pvc.yaml
kubectl get pv,pvc
```

EFS 보안 그룹은 필요한 네트워크에서만 NFS(TCP 2049) 연결을 허용하도록 설정하세요. IAM 정책과 보안 그룹 설정은 프로젝트 환경에 맞춰 검토해야 합니다.

### 4. Minecraft 및 BungeeCord 배포

서버 매니페스트는 PVC 이름, EULA, 접속 모드, 서비스 포트 등을 확인한 후 적용합니다.

```bash
kubectl apply -f P2.Game-Server/5.minecraft-server-1.yaml
kubectl apply -f P2.Game-Server/6.minecraft-server-2.yaml
kubectl get pods,svc -o wide
```

BungeeCord 구성 파일과 차트는 `P2.Game-Server/7.bungeecord/`에서 확인하세요. ConfigMap을 사용하는 경우 ConfigMap의 이름과 마운트 경로가 차트 및 매니페스트 설정과 일치해야 합니다.

### 5. ELK 로그 분석 구성

`P3.Analysis-ELK/` 아래 각 구성요소의 디렉터리에서 ConfigMap, 워크로드 및 서비스를 순서에 맞게 배포합니다. Elasticsearch가 먼저 준비되어야 Logstash와 Kibana가 연결될 수 있습니다. Kibana의 Elasticsearch 주소와 각 서비스 포트는 현재 클러스터 설정에 맞춰 지정하세요.

배포 상태와 로그를 확인합니다.

```bash
kubectl get pods,svc -A
kubectl logs deployment/filebeat -n default
kubectl logs deployment/logstash -n elk
```

Elasticsearch 및 Kibana 상태 확인용 API 주소는 서비스 조회 결과로 확인하고, 저장소에 과거에 사용한 공개 엔드포인트를 그대로 재사용하지 마세요.

## 현재 확인이 필요한 항목

- 기존 작업 메모의 일부 경로와 파일명이 현재 저장소의 `P2.Game-Server/` 파일명과 다릅니다. 실행 전에 실제 파일 경로를 확인하세요.
- Terraform 방식과 `eksctl` 방식의 EKS 생성 절차가 함께 기록되어 있습니다. 중복 생성이나 기존 리소스와의 충돌을 피하도록 배포 경로를 선택해야 합니다.
- EFS 파일 시스템 ID, 서브넷, 보안 그룹, IAM 정책 ARN, 클러스터 이름과 리전은 환경별 값입니다.
- ELK의 Elasticsearch/Kibana 주소, 네임스페이스 및 서비스 포트는 배포 후 조회한 값과 일치해야 합니다.
- `P4.Monitoring-Pro,Gra,Sla/` 디렉터리는 현재 비어 있어 README에서 상세 모니터링 절차를 설명하지 않습니다.
- 루트 프로젝트의 라이선스와 배포 검증 상태는 현재 문서에서 확인되지 않았습니다.

## 공개 저장소에 올리기 전

기존 작업 파일은 이 README를 만드는 과정에서 삭제하거나 수정하지 않았습니다. 다만 공개 저장소로 올리기 전에 다음 파일과 값이 Git에 포함되는지 직접 검토하세요.

- `terraform.tfvars`, Terraform state 파일 및 클라우드 계정/리소스 식별자
- `.ppk` 등 개인 키 파일, IAM 정책 및 인증 정보
- 기존 `프로젝트 워크플로우.txt` 안의 계정 번호, 리소스 ARN, 네트워크 ID 및 공개 엔드포인트

민감한 파일은 삭제하지 않고 보존하되, 공개가 필요한지 확인하고 필요하면 `.gitignore` 또는 Git 추적 제외 설정을 적용하세요. 이미 공개된 키나 자격 증명이 있다면 파일을 그대로 둔 채 자격 증명 자체를 교체해야 합니다.
