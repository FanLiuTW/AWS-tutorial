# AWS CLI 指令用途（通用說明）

  - `aws configure list`
    顯示目前使用中的 AWS CLI 設定值與來源（環境變數、設定檔、角色等）。

  - `aws configure list-profiles`
    列出本機已設定的所有 profile 名稱。

  - `aws iam list-attached-user-policies --user-name <user> --profile <profile>`
    列出某個 IAM 使用者掛載的「管理型政策」（AWS managed / customer managed）。

  - `aws iam list-groups-for-user --user-name <user> --profile <profile>`
    列出某個 IAM 使用者所屬的 IAM 群組。

  - `aws iam list-user-policies --user-name <user> --profile <profile>`
    列出某個 IAM 使用者的 inline policy 名稱清單。

  - `aws iam get-user-policy --user-name <user> --policy-name <name> --profile <profile>`
    取得指定 IAM 使用者的 inline policy 內容（JSON）。

  - `aws sts get-caller-identity --profile <profile>`
    回傳目前憑證對應的 AWS 身分（帳號、ARN、UserId）。

  - `aws s3 ls --profile <profile>`
    列出該身分可見的 S3 buckets（S3 連線/權限測試常用）。

  - `aws ec2 describe-instances --profile <profile>`
    查詢 EC2 instance 清單（用來測試 EC2 權限是否允許）。

# Terraform 指令（Lab3）

  - `AWS_PROFILE=<profile> terraform init`
    初始化 Terraform（下載 provider、初始化 backend）。

  - `AWS_PROFILE=<profile> terraform plan -var="tfstate_bucket_name=tfstate-<account-id>-apne1"`
    Bootstrap 的 plan（建立 remote backend 之前確認變更）。

  - `AWS_PROFILE=<profile> terraform apply -var="tfstate_bucket_name=tfstate-<account-id>-apne1"`
    Bootstrap 的 apply（建立 S3/DynamoDB）。

  - `AWS_PROFILE=<profile> terraform plan`
    環境 module 的 plan（確認變更）。

  - `AWS_PROFILE=<profile> terraform apply`
    套用資源建立或變更。

  - `AWS_PROFILE=<profile> terraform output`
    讀取 outputs（例如 public ip / ssh 指令）。

  - `AWS_PROFILE=<profile> terraform state list`
    查看目前 state 裡的資源列表。

  - `AWS_PROFILE=<profile> terraform state show <address>`
    查看指定資源在 state 裡的詳細資料。

  - `AWS_PROFILE=<profile> terraform destroy -var="tfstate_bucket_name=tfstate-<account-id>-apne1"`
    刪除 bootstrap 建立的 backend（S3/DynamoDB）。

  - `AWS_PROFILE=<profile> terraform destroy`
    刪除環境資源（EC2/SG/Key Pair）。
