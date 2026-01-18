# IAM Role Deep Dive（完整理解版）

> **一句話定義**
>
> **IAM Role 是一個「可被 Assume 的身份」，  
> 本身沒有長期憑證，  
> 透過 STS 提供 Temporary Credentials。**

---

## 一、為什麼 IAM Role 會讓人覺得抽象？

因為它 **不是人、不是帳號、也不能登入**。

錯誤理解 ❌  
> Role = 另一種 User  

正確理解 ✅  
> **Role = 一個「暫時身份」**

---

## 二、IAM Role 解決了什麼問題？

### 如果沒有 Role（危險設計）

```text
EC2
 └── 放 IAM User Access Key
        └── 權限通常過大
```

問題：
- Access Key 可能外洩
- 無法自動輪替
- 無法限制使用時間

---

### IAM Role 的核心目標

> **讓某個主體，在某段時間內，  
> 以最小權限存取 AWS 資源**

三個關鍵：
- 誰可以用（Trust）
- 用多久（STS）
- 能做什麼（Policy）

---

## 三、IAM Role 的三大組成

image_group{"query":["AWS IAM role trust policy diagram","AWS assume role flow diagram","AWS STS temporary credentials"]}

---

### 1️⃣ Trust Policy（誰可以 Assume 我）

```json
{
  "Effect": "Allow",
  "Principal": {
    "Service": "ec2.amazonaws.com"
  },
  "Action": "sts:AssumeRole"
}
```

用途：
- 定義「誰可以使用這個 Role」
- 常見 Principal：
  - ec2.amazonaws.com
  - lambda.amazonaws.com
  - 另一個 AWS Account
  - IAM User / Role

---

### 2️⃣ Permission Policy（假扮後能做什麼）

```json
{
  "Effect": "Allow",
  "Action": "s3:GetObject",
  "Resource": "arn:aws:s3:::my-bucket/*"
}
```

👉 跟 User 的 Policy 完全一樣

---

### 3️⃣ STS Temporary Credentials（實際在用）

```text
AccessKeyId
SecretAccessKey
SessionToken
有效期限：15 分鐘 ～ 12 小時
```

特性：
- 自動過期
- 自動輪替
- 無法長期濫用

---

## 四、完整 Assume Role 流程（一定要懂）

```text
[Caller]
   |
   | sts:AssumeRole
   v
[IAM Role]
   |
   | Trust Policy 檢查
   v
[AWS STS]
   |
   | 發放 Temporary Credentials
   v
[呼叫 AWS API]
```

---

## 五、三大經典使用場景

### 🖥 EC2 存取 S3

```text
EC2
 └── IAM Role
        └── S3:GetObject
```

原因：
- 不需要 Access Key
- 最安全

---

### 🔁 跨帳號存取

```text
Account A User
 └── Assume Role
        └── Account B Role
              └── ReadOnly
```

Trust Policy 範例：

```json
{
  "Principal": {
    "AWS": "arn:aws:iam::ACCOUNT_A:root"
  }
}
```

---

### 🔐 SSO / OIDC

```text
Google / Azure AD
 └── OIDC
        └── IAM Role
              └── AWS 權限
```

👉 不需要 IAM User

---

## 六、Role vs User（超重要）

| 項目 | IAM User | IAM Role |
|---|---|---|
| 能否登入 | ✅ | ❌ |
| 長期 Access Key | ✅ | ❌ |
| 臨時憑證 | ❌ | ✅ |
| 常見用途 | 人類使用 | 系統 / 跨帳號 |

---

## 七、Terraform 中的 Role（必看）

```hcl
resource "aws_iam_role" "example" {
  assume_role_policy = jsonencode({
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}
```

> **assume_role_policy = Trust Policy**

---

## 八、面試一句話版本

> **IAM Role 是透過 STS 提供臨時權限的身份，  
> 用於 AWS Service、跨帳號與短期存取場景。**

---

## 九、自我檢查清單

- Role 有沒有 Access Key？ ❌  
- Role 能不能登入 Console？ ❌  
- Role 一定搭配 STS？ ✅  
- Role 能不能被 Assume？ ✅  

---

## 十、延伸主題

- AssumeRole vs PassRole
- External ID
- Role Chaining
- Terraform IAM Best Practice
