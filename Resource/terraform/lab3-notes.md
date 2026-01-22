# Lab3: Terraform + Terragrunt 實作筆記

這份筆記整理了本次 Lab3 的流程、檔案用途、原理與踩坑紀錄，方便後續複習。

## 1) 這次做了什麼
- 使用 Terraform 建立 EC2（Ubuntu）、Security Group、Key Pair。
- 使用 S3 + DynamoDB 做 Remote Backend + Lock。
- 用 Terragrunt 跑同一套 module，體驗集中管理。
- 將可變參數改用 variables，並用 outputs 輸出 public ip/ssh 指令。

## 2) 目錄與檔案用途（`AWS-tutorial/lab/task3`）

### bootstrap/
- `main.tf`：建立 S3 bucket（state）、DynamoDB table（lock）。
- `variables.tf`：backend 用到的變數（region、bucket name、lock table）。
- `versions.tf`：Terraform 與 AWS provider 版本。
- `outputs.tf`：輸出 bucket 名稱與 lock table 名稱。

### terraform-live/
- `modules/ec2/main.tf`：EC2 module，包含 AMI、SG、Key Pair、EC2 實例。
- `modules/ec2/variables.tf`：EC2 module 的參數。
- `modules/ec2/outputs.tf`：輸出 instance id、public ip、ssh 指令。

- `envs/dev/backend.tf`：S3 remote backend 設定。
- `envs/dev/providers.tf`：AWS provider 與 default tags。
- `envs/dev/versions.tf`：Terraform 與 provider 版本。
- `envs/dev/variables.tf`：root module 變數。
- `envs/dev/main.tf`：呼叫 EC2 module。
- `envs/dev/terraform.tfvars`：dev 環境實際值（region、cidr、key path 等）。
- `envs/dev/outputs.tf`：輸出 module 的資訊。

### terragrunt-live/
- `live/terragrunt.hcl`：集中管理 provider、region、tags。
- `live/dev/ap-northeast-1/ec2/terragrunt.hcl`：指定 module、inputs、remote_state。
- `modules/ec2/*`：Terragrunt 使用的 module（同 Terraform 的 module）。

### keys/
- `id_ed25519`：本機私鑰（用來 SSH 登入 EC2）。
- `id_ed25519.pub`：公鑰（上傳成 AWS Key Pair）。

### README.md / diagrams/
- `README.md`：流程步驟與架構圖連結。
- `diagrams/architecture.png`：架構圖（需要你自行產生）。

## 3) 核心原理

### Terraform Module 與 Root Module
- Module：一組可重用的資源定義（EC2/SG/Key Pair）。
- Root module：針對某個環境組合 module 與變數。

### Remote Backend
- S3 儲存 Terraform state，避免本機遺失。
- DynamoDB Lock 防止多人同時 apply。

### Terragrunt
- 把 backend/provider/tags 集中管理在上層。
- 子環境只寫 inputs，快速複製新環境。
- 缺點是多一層工具，debug 時需要理解 `.terragrunt-cache` 的運作。

## 4) 你踩到的坑與原因

### (1) Terraform 拿不到 AWS credentials
**現象**：`No valid credential sources found`。
**原因**：Terraform 沒讀到正確的 AWS profile。
**解法**：用 `AWS_PROFILE=root terraform ...` 指定 profile。

### (2) 找不到 public key
**現象**：`no file exists at ../../keys/id_ed25519.pub`。
**原因**：`file()` 會以 root module 路徑為基準，Terragrunt 還會把 module 複製進 `.terragrunt-cache`，相對路徑失效。
**解法**：改成絕對路徑，例如：
``。

### (3) Terragrunt remote_state 報錯
**現象**：`Found remote_state settings ... but no backend block`。
**原因**：Terragrunt 需要 module 中有 `terraform { backend "s3" {} }` 空宣告。
**解法**：在 module `main.tf` 加上空的 backend block。

### (4) S3 bucket 刪不掉
**現象**：`BucketNotEmpty`。
**原因**：S3 bucket 開啟版本控管，有 object versions / delete markers。
**解法**：先用 `aws s3api` 清空 versions，再 `terraform destroy`。

### (5) SSH 指令的帳號錯誤
**原因**：Ubuntu 預設使用者是 `ubuntu`，不是 `ec2-user`。
**解法**：`ssh -i <private-key-path> ubuntu@<public-ip>`。

### (6) IP 使用錯誤
**原因**：`192.168.x.x` 是內網 IP，無法從外網連到 EC2。
**解法**：改成公網 IPv4，例如 ``。

## 5) 主要指令整理

### Bootstrap（建立 backend）
```bash
cd bootstrap
AWS_PROFILE=root terraform init
AWS_PROFILE=root terraform plan -var="tfstate_bucket_name="
AWS_PROFILE=root terraform apply -var="tfstate_bucket_name="
```

### Terraform live (dev)
```bash
cd ../terraform-live/envs/dev
AWS_PROFILE=root terraform init
AWS_PROFILE=root terraform plan
AWS_PROFILE=root terraform apply
AWS_PROFILE=root terraform output
```

### Terragrunt (dev)
```bash
cd ../../terragrunt-live/live/dev/ap-northeast-1/ec2
AWS_PROFILE=root terragrunt init
AWS_PROFILE=root terragrunt plan
AWS_PROFILE=root terragrunt apply
```

### Destroy
```bash
cd terraform-live/envs/dev
AWS_PROFILE=root terraform destroy
```

若要刪 bootstrap：
```bash
cd ../../bootstrap
AWS_PROFILE=root terraform destroy -var="tfstate_bucket_name="
```

## 6) 你現在的 SSH 指令
```bash
ssh -i  ubuntu@<EC2_PUBLIC_IP>
```

---
這份筆記可以直接當作作業說明附在 repo 內。
