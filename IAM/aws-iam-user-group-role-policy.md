# AWS IAM：User / Group / Role / Policy 關係與 Policy 格式整理

> **一句話總結**
>
> **User / Role 是「身份（Identity）」  
> Policy 是「權限（Permission）」  
> Group 只是「管理 User 的容器」**

---

## 一、IAM 四大元件是什麼？

### 🧑 IAM User
- 代表「一個人或一個程式」
- 可登入 Console / 使用 Access Key
- **本身不定義權限**

---

### 👥 IAM Group
- User 的集合
- 只為了**方便管理權限**
- Group 不能登入、不能被 assume

---

### 🎭 IAM Role
- 可被 **Assume（假扮）** 的身份
- 沒有長期密碼或 Access Key
- 常用於：
  - EC2 / Lambda
  - 跨帳號存取
  - SSO / OIDC

---

### 📜 IAM Policy
- **真正定義「可以做什麼」**
- JSON 格式
- Policy 本身不會生效，必須 attach

---

## 二、彼此之間的關係（一定要會畫）

### 可以 attach Policy 的對象

| 對象 | 可 attach Policy |
|---|---|
| IAM User | ✅ |
| IAM Group | ✅ |
| IAM Role | ✅ |

---

### 不存在 / 常被誤會的關係

| 關係 | 是否存在 |
|---|---|
| Group ➜ Role | ❌ |
| Role ➜ User | ❌（只能 assume） |
| Policy ➜ Policy | ❌ |

---

### 關係總覽圖（文字版）

```text
IAM Policy
 ├── attach to IAM User
 ├── attach to IAM Group ── contains ──> IAM User
 └── attach to IAM Role ── assumed by ──> User / AWS Service
```

---

## 三、IAM Policy 的格式（超重要）

### 基本結構

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::example-bucket"
    }
  ]
}
```

---

### Policy 五大核心欄位

| 欄位 | 說明 |
|---|---|
| Version | Policy 語言版本（幾乎固定） |
| Statement | 權限規則（可多筆） |
| Effect | Allow / Deny |
| Action | AWS API 行為 |
| Resource | 資源 ARN |
| Condition | 條件限制（選填） |

---

### 多 Statement + Deny 範例

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeInstances",
        "ec2:StartInstances"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Deny",
      "Action": "ec2:TerminateInstances",
      "Resource": "*"
    }
  ]
}
```

> ⚠️ **Deny 永遠優先於 Allow**

---

## 四、實務搭配範例

### 工程師帳號

```text
IAM User (Alice)
  └── IAM Group (BackendDev)
        └── Policy (EC2 + S3 limited)
```

---

### EC2 存取 S3

```text
EC2
  └── IAM Role
        └── Policy (S3:GetObject)
```

---

### 跨帳號存取

```text
Account A User
  └── assume IAM Role (Account B)
        └── Policy (ReadOnly)
```

---

## 五、面試一句話版本

> **User / Role 是身份，Policy 是權限；  
> Group 只是為了方便管理 User。**

---

## 六、常見陷阱

- ❌ 用 User 直接給超大權限
- ❌ 用 Access Key 放在程式碼
- ❌ 不用 Role 給 EC2 / Lambda
- ❌ 忽略 Deny 的優先權

---

## 七、延伸閱讀

- IAM User vs IAM Role
- Terraform 管理 IAM
- AWS IAM Security Best Practice
