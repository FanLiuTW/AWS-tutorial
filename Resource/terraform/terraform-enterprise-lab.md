
# Terraform 企業級實戰練習指南
> 目標：同一個 Repo 內，完成 **兩種企業常見 IaC 架構**
>
> 1. **Terraform（Module + Multi-env + Remote Backend + Lock）**
> 2. **Terragrunt（Module + Live + Remote State 集中管理）**

---

## 一、整體 Repo 結構

```
infra-lab/
  README.md
  diagrams/
    architecture.png

  bootstrap/
    main.tf
    versions.tf
    variables.tf
    outputs.tf

  terraform-live/
    modules/
      ec2/
        main.tf
        variables.tf
        outputs.tf
    envs/
      dev/
        backend.tf
        providers.tf
        main.tf
        terraform.tfvars
      prod/
        backend.tf
        providers.tf
        main.tf
        terraform.tfvars

  terragrunt-live/
    modules/
      ec2/
        main.tf
        variables.tf
        outputs.tf
    live/
      terragrunt.hcl
      dev/ap-northeast-1/ec2/terragrunt.hcl
      prod/ap-northeast-1/ec2/terragrunt.hcl
```

---

## 二、Bootstrap（一次性建立 Remote Backend）

### bootstrap/versions.tf
```hcl
terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

### bootstrap/variables.tf
```hcl
variable "aws_region" {
  type    = string
  default = "ap-northeast-1"
}

variable "tfstate_bucket_name" {
  type = string
}

variable "dynamodb_lock_table_name" {
  type    = string
  default = "terraform-locks"
}
```

### bootstrap/main.tf
```hcl
provider "aws" {
  region = var.aws_region
}

resource "aws_s3_bucket" "tfstate" {
  bucket = var.tfstate_bucket_name
}

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket                  = aws_s3_bucket.tfstate.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "lock" {
  name         = var.dynamodb_lock_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
```

### 執行
```bash
cd bootstrap
terraform init
terraform apply -var="tfstate_bucket_name=tfstate-<account-id>-apne1"
```

---

## 三、A 路線：Terraform（不用 Terragrunt）

### 核心觀念
- Module：定義資源
- envs：每個環境一個 root module
- backend：每個環境一份，確保 state 隔離
- DynamoDB：避免多人同時 apply

### terraform-live/envs/dev/backend.tf
```hcl
terraform {
  backend "s3" {
    bucket         = "tfstate-<account-id>-apne1"
    key            = "infra-lab/dev/ec2/terraform.tfstate"
    region         = "ap-northeast-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
```

### terraform-live/envs/dev/providers.tf
```hcl
provider "aws" {
  region = var.aws_region
  default_tags {
    tags = merge(var.tags, {
      ManagedBy = "terraform"
    })
  }
}
```

### terraform-live/envs/dev/main.tf
```hcl
module "ec2" {
  source           = "../../modules/ec2"
  project          = var.project
  env              = var.env
  aws_region       = var.aws_region
  allowed_ssh_cidr = var.allowed_ssh_cidr
  instance_type    = var.instance_type
  key_name         = var.key_name
  public_key_path  = var.public_key_path
  tags             = var.tags
}
```

### terraform-live/envs/dev/terraform.tfvars
```hcl
project          = "infra-lab"
env              = "dev"
aws_region       = "ap-northeast-1"
allowed_ssh_cidr = "YOUR_IP/32"
key_name         = "infra-lab-dev-key"
public_key_path  = "~/.ssh/id_ed25519.pub"

tags = {
  Owner      = "Fan Liu"
  CostCenter = "learning"
}
```

### 操作
```bash
cd terraform-live/envs/dev
terraform init
terraform plan
terraform apply
terraform output
```

---

## 四、B 路線：Terragrunt

### 優點
- backend / provider / tag 集中管理
- 多環境複製成本極低
- 非常適合中大型企業

### terragrunt-live/live/terragrunt.hcl
```hcl
locals {
  region = "ap-northeast-1"
  common_tags = {
    ManagedBy = "terragrunt"
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = <<EOF
provider "aws" {
  region = "${local.region}"
  default_tags {
    tags = ${jsonencode(local.common_tags)}
  }
}
EOF
}
```

### terragrunt-live/live/dev/ap-northeast-1/ec2/terragrunt.hcl
```hcl
terraform {
  source = "../../../../modules/ec2"
}

inputs = {
  project          = "infra-lab"
  env              = "dev"
  aws_region       = "ap-northeast-1"
  allowed_ssh_cidr = "YOUR_IP/32"
  instance_type    = "t3.micro"
  key_name         = "infra-lab-dev-key"
  public_key_path  = "~/.ssh/id_ed25519.pub"
  tags = {
    Owner = "Fan Liu"
    Env   = "dev"
  }
}

remote_state {
  backend = "s3"
  config = {
    bucket         = "tfstate-<account-id>-apne1"
    key            = "infra-lab/dev/ec2/terraform.tfstate"
    region         = "ap-northeast-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
```

### 操作
```bash
cd terragrunt-live/live/dev/ap-northeast-1/ec2
terragrunt init
terragrunt plan
terragrunt apply
```

---

## 五、README 架構圖

```md
## Architecture
![architecture](./diagrams/architecture.png)
```

---

## 六、驗收清單（企業級）

- Remote state 成功寫入 S3
- DynamoDB lock 正常生效
- terraform / terragrunt output 可取得 public ip、ssh 指令
- README 含架構圖、操作步驟、安全提醒
- 作業結束可 terraform destroy，避免成本浪費

---

完成以上內容，你已具備 **企業級 Terraform + Terragrunt 的實戰基礎能力**。
