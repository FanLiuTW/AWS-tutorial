# Terraform 企業級實戰練習（Remote Backend 與 Terragrunt）

> 目標：用**企業級 DevOps 視角**練習 Terraform，一次掌握  
> - Remote Backend + State Lock  
> - Module + 多環境  
> - Terraform 原生 vs Terragrunt 差異  

---

## 目錄
1. 學習目標
2. Repo 結構
3. Bootstrap（S3 + DynamoDB Lock）
4. 路線 A：純 Terraform（不用 Terragrunt）
5. 路線 B：Terragrunt
6. 架構圖（draw.io）
7. 驗收清單
8. 清理資源

---

## 1. 學習目標

你將完成兩種**真實企業常見 Terraform 架構**：

### 路線 A（很多公司仍在用）
- Terraform only
- Module 化
- Multi-env（dev / prod）
- S3 Remote Backend
- DynamoDB State Lock

### 路線 B（中大型組織主流）
- Terraform + Terragrunt
- Module / Live 分離
- Backend / Provider / Tag 統一管理

---

## 2. Repo 結構

```
infra-lab/
├── README.md
├── diagrams/
│   └── architecture.png
├── bootstrap/
│   ├── main.tf
│   ├── versions.tf
│   ├── variables.tf
│   └── outputs.tf
├── terraform-live/
│   ├── modules/
│   │   └── ec2/
│   └── envs/
│       ├── dev/
│       └── prod/
└── terragrunt-live/
    ├── modules/
    │   └── ec2/
    └── live/
        ├── terragrunt.hcl
        ├── dev/ap-northeast-1/ec2/
        └── prod/ap-northeast-1/ec2/
```

---

## 3. Bootstrap：Remote Backend（只做一次）

### 功能
- S3：存 terraform.tfstate（Versioning + Encryption）
- DynamoDB：State Lock（避免多人同時 apply）

### 執行
```bash
cd bootstrap
terraform init
terraform apply \
  -var="tfstate_bucket_name=tfstate-<account-id>-apne1"
```

---

## 4. 路線 A：不用 Terragrunt

### 執行 dev
```bash
cd terraform-live/envs/dev
terraform init
terraform plan
terraform apply
```

### 特點
- 原生 Terraform
- backend 每個 env 一份
- 容易 debug

---

## 5. 路線 B：Terragrunt

### 執行 dev
```bash
cd terragrunt-live/live/dev/ap-northeast-1/ec2
terragrunt init
terragrunt plan
terragrunt apply
```

### 特點
- backend / provider 集中管理
- 幾乎零重複設定
- 適合多環境、多帳號

---

## 6. 架構圖（draw.io）

README 引用方式：
```md
![architecture](./diagrams/architecture.png)
```

---

## 7. 驗收清單（企業級）

- [ ] tfstate 存在 S3
- [ ] DynamoDB Lock 生效
- [ ] terraform / terragrunt output 正常
- [ ] SSH CIDR 非 0.0.0.0/0（或 README 有說明）
- [ ] 資源有 tags（Owner / Env）

---

## 8. 清理資源（避免燒錢）

### Terraform
```bash
terraform destroy
```

### Terragrunt
```bash
terragrunt destroy
```

---

## 結語

如果你能清楚解釋：
- 為什麼要 Remote Backend + Lock
- Terraform vs Terragrunt 的取捨

你已經不是新手，而是 **Junior → Mid DevOps 等級**。

（文件結束）
