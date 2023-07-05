
目錄
- [Introduction](#introduction)
- [Architecture](#architecture)
- [Prerequisite](#prerequisite)
- [Installation](#installation)
  - [PostgreSQL (For Ubuntu 20.04)](#postgresql-for-ubuntu-2004)
    - [Install](#install)
    - [Settings](#settings)
    - [Create Database User](#create-database-user)
    - [Grant Database Access](#grant-database-access)
  - [Helm 3](#helm-3)
    - [Install](#install-1)
  - [Kubernetes RBAC](#kubernetes-rbac)
    - [建立 Private Key](#建立-private-key)
    - [建立 CSR](#建立-csr)
    - [申請 Kubernetes 證書](#申請-kubernetes-證書)
    - [建立 kubeconfig](#建立-kubeconfig)
    - [Jenkins 的 RBAC 授權](#jenkins-的-rbac-授權)
      - [建立 Namespace](#建立-namespace)
      - [建立 ClusterRole](#建立-clusterrole)
      - [建立 RoleBinding](#建立-rolebinding)
      - [測試權限](#測試權限)


# Introduction
該專案目前用於自學如何使用 Jenkins pipeline 透過 Helm3 部署 Kubernetes Application


# Architecture


![](Architecture.jpg)
說明:
1. 開發人員 Push Code 至 Gitlab
2. 建立各環境 Jenkins Job (SIT / STG / PROD)
3. 各環境 Jenkins Job 會做以下幾件事
   - 依據 git commit tag 作為 container tag 並 push 至 docker hub 
   - 使用不同的 kubeconfig 並透過 Helm3 管理對應環境的 namespace
4. 因考慮到較少公司直接將 DB 使用Container , 故還是使用 VM , 透過自定義 EndPoints , 讓內部容器與DB連線

![](Architecture1.jpg)
說明:
1. 依據 git commit tag 作為 container tag 並 push 至 docker hub 
2. 由 Helm3 管理 Kubernetes Cluster , 拉取指定的 commit tag


# Prerequisite
- Jenkins ( Use Jenkins pipeline )
- PostgreSQL
- Helm 3
- Kubernetes Cluster
  - Jenkins User
- Docker hub account


# Installation

## PostgreSQL (For Ubuntu 20.04)

### Install 
```shell
sudo apt update
sudo apt install postgresql postgresql-contrib
sudo systemctl enable postgresql.service --now
```

### Settings

```shell
# 修改主配置檔
vim /etc/postgresql/12/main/postgresql.conf

# 修改監聽IP , 預設為127.0.0.1 , 改為* , 機器上所有網卡都監聽
listen_addresses = '*'

# 修改連線白名單
vim /etc/postgresql/12/main/pg_hba.conf

# 在最後加入這段允許所有用戶在所有網段連接（安全上有問題,因為是Lab所以這樣設定, 不要再生產環境這樣做）
host    all             all             0.0.0.0/0               md5

# 重啟套用配置
sudo systemctl restart postgresql.service
```

### Create Database User

```shell

# 切換用戶名稱
root@postgresql:~# su - postgres

# 進入postgres命令行
postgres@postgresql:~$ psql

psql (12.14 (Ubuntu 12.14-0ubuntu0.20.04.1))
Type "help" for help.

-- 語法： CREATE USER myuser WITH PASSWORD 'secret_passwd';
-- 建立使用者帳號 , 將 帳號 myuser 及密碼 secret_passwd 替換成實際的用戶及密碼
postgres=# CREATE USER django_lab WITH PASSWORD 'django_lab';
CREATE ROLE

```

### Grant Database Access

```shell
root@postgresql:~# su - postgres

# 進入postgres命令行
postgres@postgresql:~$ psql

psql (12.14 (Ubuntu 12.14-0ubuntu0.20.04.1))
Type "help" for help.

-- 語法：CREATE DATABASE database_name;
-- 建立資料庫 , 將 database_name 替換成實際資料庫名稱
postgres=# CREATE DATABASE django_lab;
CREATE DATABASE

-- 語法：GRANT ALL PRIVILEGES ON DATABASE database_name TO username;
-- 授權指定使用者對指定Database擁有所有使用權 , 將 database_name 以及 username 替換成實際DB名稱以及用戶
postgres=# GRANT ALL PRIVILEGES ON DATABASE django_lab TO django_lab;
GRANT


```


## Helm 3

### Install
```shell
# 下載安裝腳本
$ curl -O https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3

# 安裝
$ bash ./get-helm-3

# 驗證helm二進制文件可以執行 , 顯示對應版本
$ helm version
```



## Kubernetes RBAC


### 建立 Private Key

```bash
# For SIT environment
$ openssl genrsa -out sit-jenkins.key 2048

# For STG environment
$ openssl genrsa -out stg-jenkins.key 2048

# For PROD environment
$ openssl genrsa -out prod-jenkins.key 2048
```

### 建立 CSR

```bash
# 建立每個環境 user 的 csr, (CN=<your env user name>)

# SIT 環境
$ openssl req -new -key sit-jenkins.key -out sit-jenkins.csr -subj "/CN=sit-jenkins"

# STG 環境
$ openssl req -new -key stg-jenkins.key -out stg-jenkins.csr -subj "/CN=stg-jenkins"

# PROD 環境
$ openssl req -new -key prod-jenkins.key -out prod-jenkins.csr -subj "/CN=prod-jenkins"
```

### 申請 Kubernetes 證書
這邊先用SIT環境作為範例 , 其餘STG以及PROD方法相同

```shell
# 先取得 CSR 的內容 , 而內容需要由base64進行encode , 且不能有斷行 , 所以要加上參數-w 0（CSR可以看作是證書申請文件)
$ cat sit-jenkins.csr | base64 -w 0 
LS0tLS1CRUdJTiBDRVJUSUZJQ0FURSBSRVFVRVNULS0tLS0KTUlJQ1Z6Q0NBVDhDQVFBd0VqRVFNQTRHQTFVRUF3d0hhbVZ1YTJsdWN6Q0NBU0l3RFFZSktvWklodmNOQVFFQgpCUUFEZ2dFUEFEQ0NBUW9DZ2dFQkFLNHpkSGF4N3d2VmlxalVxOG93MFB2ZDJuRVdTQlFFWVg3QSs0VFppVFRnCnJkMitST2VNdmU0U2xzWWNLQ0J5U2xHOVZNSjk5d0pVTTlKaVNjMVova0h0WE9zdWtlcWVTYUpuN1FhWDZPaHQKMCsvRERKaGFIMTFwcEFwL2x6S2hYSGRNbS82WkNEWG11R01KSm9NUk54ZmtVVGFaTEx6MzhEck5PWXdjb05wUQpwT1hVeWxZaWYyQy9mRWtCVm4rWFhBRS9zN3NPdXFOR1V0Rzk0ZTJLeUlxNzFTZWlVZE1mSGZYdmtIVmptU3NvClc3Rkp3ditVTEpkbW1lakhlYUN1eTNnSXNGRjR1QVBEUzhYcWhwOXNVUUhqWHl4MXhQQUdRUVlxUlc2NEYraTAKeFhLdzI5Nm1YbWpvcTgvK3ozemNPbzNnY3k0bTZUaGVTSEh1Y2h3NUlzTUNBd0VBQWFBQU1BMEdDU3FHU0liMwpEUUVCQ3dVQUE0SUJBUUI4eDdqc2FScnJlcjcwNEFEL1V4bmFGM3lhQ21MMEY3VUtxVWM2SHVGQTlNWW9FZjN4CjQrNU9iUmxCQVVnRGswbFQ5QlhMck9iQTBLaGFCZEZ2b3cvamFodTJPYTBqSnhXOEZQYVBEZ2JMWDYvTlZJcFMKQS9JTUsrWkNTNnp3TXdzZ0FVTGZPcG5NZm41VzVkMVZsSGRKV3RpZ0JOODJ5UlFPSzBXdTF1T0VzTmN5QUQybQpqVkdLTG45VkhqdE5RVmhub09SNmErQW55WHgySXFzQ21CcDkrN3RzSExDQ3NwV2xBOXRZblNVWGFyVDAydGNWCm02dkN2aE5BOVorOEFZTVgyRDNyUDVqSjJEcEFzSTk1SUxucmpES3JsVHY5bFFDakRGRDJodCswRVdXNXNqbjQKbk1yL0x0Zzg0amFJaEFlMUw4ZVBqcTliWHhjVms1U29zRk1RCi0tLS0tRU5EIENFUlRJRklDQVRFIFJFUVVFU1QtLS0tLQo=


# 建立 k8s 證書申請(CertificateSigningRequest)的 yaml file (依序將每個使用者的CSR建立)
$ cat << EOF > sit-jenkins-user-csr.yaml
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: sit-jenkins-user
spec:
  groups:
    - system:authenticated
  request: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURSBSRVFVRVNULS0tLS0KTUlJQ1Z6Q0NBVDhDQVFBd0VqRVFNQTRHQTFVRUF3d0hhbVZ1YTJsdWN6Q0NBU0l3RFFZSktvWklodmNOQVFFQgpCUUFEZ2dFUEFEQ0NBUW9DZ2dFQkFLNHpkSGF4N3d2VmlxalVxOG93MFB2ZDJuRVdTQlFFWVg3QSs0VFppVFRnCnJkMitST2VNdmU0U2xzWWNLQ0J5U2xHOVZNSjk5d0pVTTlKaVNjMVova0h0WE9zdWtlcWVTYUpuN1FhWDZPaHQKMCsvRERKaGFIMTFwcEFwL2x6S2hYSGRNbS82WkNEWG11R01KSm9NUk54ZmtVVGFaTEx6MzhEck5PWXdjb05wUQpwT1hVeWxZaWYyQy9mRWtCVm4rWFhBRS9zN3NPdXFOR1V0Rzk0ZTJLeUlxNzFTZWlVZE1mSGZYdmtIVmptU3NvClc3Rkp3ditVTEpkbW1lakhlYUN1eTNnSXNGRjR1QVBEUzhYcWhwOXNVUUhqWHl4MXhQQUdRUVlxUlc2NEYraTAKeFhLdzI5Nm1YbWpvcTgvK3ozemNPbzNnY3k0bTZUaGVTSEh1Y2h3NUlzTUNBd0VBQWFBQU1BMEdDU3FHU0liMwpEUUVCQ3dVQUE0SUJBUUI4eDdqc2FScnJlcjcwNEFEL1V4bmFGM3lhQ21MMEY3VUtxVWM2SHVGQTlNWW9FZjN4CjQrNU9iUmxCQVVnRGswbFQ5QlhMck9iQTBLaGFCZEZ2b3cvamFodTJPYTBqSnhXOEZQYVBEZ2JMWDYvTlZJcFMKQS9JTUsrWkNTNnp3TXdzZ0FVTGZPcG5NZm41VzVkMVZsSGRKV3RpZ0JOODJ5UlFPSzBXdTF1T0VzTmN5QUQybQpqVkdLTG45VkhqdE5RVmhub09SNmErQW55WHgySXFzQ21CcDkrN3RzSExDQ3NwV2xBOXRZblNVWGFyVDAydGNWCm02dkN2aE5BOVorOEFZTVgyRDNyUDVqSjJEcEFzSTk1SUxucmpES3JsVHY5bFFDakRGRDJodCswRVdXNXNqbjQKbk1yL0x0Zzg0amFJaEFlMUw4ZVBqcTliWHhjVms1U29zRk1RCi0tLS0tRU5EIENFUlRJRklDQVRFIFJFUVVFU1QtLS0tLQo=
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 315569260
  usages:
    - digital signature
    - key encipherment
    - client auth
EOF
# 備注: usages說明
# TLS客戶端證書的請求通行要求："digital signature" / "key encipherment" / "client auth"
# TLS 服務證書的請求通常要求："key encipherment" / "digital signature" / "server auth"

# 套用
$ kubectl create -f sit-jenkins-user-csr.yaml

# 查看CSR列表
$ kubectl get csr

# Approve 申請
$ kubectl certificate approve sit-jenkins-user

# 取得實際Client整書內容
$ kubectl get csr sit-jenkins-user -o jsonpath='{.status.certificate}' | base64 -d > sit-jenkins.crt

```

### 建立 kubeconfig

這邊先用SIT環境作為範例 , 其餘STG以及PROD方法相同

```shell
$ kubectl config --kubeconfig=sit-jenkins-kubeconfig.yml set-cluster kubernetes --server https://10.211.55.11:6443 --insecure-skip-tls-verify
$ kubectl config --kubeconfig=sit-jenkins-kubeconfig.yml set-credentials sit-jenkins --client-certificate=sit-jenkins.crt --client-key=sit-jenkins.key --embed-certs=true
$ kubectl config --kubeconfig=sit-jenkins-kubeconfig.yml set-context default --cluster=kubernetes --user=sit-jenkins --namespace sit
$ kubectl config --kubeconfig=sit-jenkins-kubeconfig.yml use-context default

# 此時因為還沒建立jenkins用戶的RBAC , 所以會出現沒有相關權限
$ kubectl get pods -n devops --kubeconfig jenkins-kubeconfig.yml
Error from server (Forbidden): pods is forbidden: User "jenkins" cannot list resource "pods" in API group "" in the namespace "devops"

```

###  Jenkins 的 RBAC 授權

ClusterRole

| ClusterRole | Resource | Verb | apiGroups |
| --- | --- | --- | --- |
| jenkins-deploy | * | * | "" |
|  | * | * | apps |


RoleBinding

| User | ClusterRole | Namespace |
| --- | --- | --- |
| sit-jenkins | jenkins-deploy | sit |
| stg-jenkins | jenkins-deploy | stg |
| prod-jenkins | jenkins-deploy | prod |


#### 建立 Namespace

```shell
kubectl create namespace sit
kubectl create namespace stg
kubectl create namespace prod
```

#### 建立 ClusterRole
```shell
cat > jenkins_deploy_cluster_role.yaml << EOF
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: jenkins_deploy_cluster_role
rules:
  - apiGroups: [""]
    resources: ["*"]
    verbs: ["*"]
  - apiGroups: ["apps"]
    resources: ["*"]
    verbs: ["*"]
EOF
```

#### 建立 RoleBinding

SIT
```shell
cat > sit_jenkins_deploy_rolebinding.yaml << EOF
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: jenkins_deploy_role_binding
  namespace: sit
subjects:
- kind: User
  name: sit-jenkins
  apiGroup: rbac.authorization.k8s.io
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: jenkins_deploy_cluster_role
EOF
```

STG
```shell
cat > stg_jenkins_deploy_rolebinding.yaml << EOF
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: jenkins_deploy_role_binding
  namespace: stg
subjects:
- kind: User
  name: stg-jenkins
  apiGroup: rbac.authorization.k8s.io
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: jenkins_deploy_cluster_role
EOF
```

PROD
```shell
cat > prod_jenkins_deploy_rolebinding.yaml << EOF
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: jenkins_deploy_role_binding
  namespace: prod
subjects:
- kind: User
  name: prod-jenkins
  apiGroup: rbac.authorization.k8s.io
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: jenkins_deploy_cluster_role
EOF
```



#### 測試權限

```shell
# 有兩種方法可以測試權限 ,
# 1. 一種是用 kubectl auth can-i 方式測試 
# 2. 另一種是用剛剛產生的 kubeconfig 進行測試


$ kubectl auth can-i get pods -n sit --as sit-jenkins
yes

$ kubectl get pods -n sit --kubeconfig sit-jenkins-kubeconfig.yml
No resources found in devops namespace.
```


