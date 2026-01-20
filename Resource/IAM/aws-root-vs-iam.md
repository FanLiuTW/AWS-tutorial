# AWS Root User vs IAM User 差異整理

> **重點一句話**
>
> **Root User 是帳號擁有者，只用來做帳號級操作；  
> IAM User 是實際操作 AWS 資源的身份。**

---

## 一、AWS Root User 是什麼？

**Root User = AWS 帳號的最高權限擁有者**

### Root User 特性
- 建立 AWS 帳號時自動產生
- 使用 Email + 密碼登入
- 擁有 **所有 AWS 服務與資源的完整權限**
- 權限 **無法被 IAM Policy 限制**

### Root User 能做但 IAM User 做不到的事
- 修改帳號擁有者 Email
- 關閉 AWS 帳號
- 管理帳單與付款方式
- 管理 AWS Organizations
- 建立 / 刪除 IAM（最上層）

---

## 二、IAM User 是什麼？

**IAM User = 實際操作 AWS 的使用者身份**

### IAM User 特性
- 由 Root 或 IAM Admin 建立
- 可以有：
  - Console 密碼
  - Access Key（CLI / SDK）
- 權限 **完全由 IAM Policy 控制**
- 可限制、可刪除、可停用

---

## 三、Root User vs IAM User 對照表

| 項目 | Root User | IAM User |
|---|---|---|
| 建立方式 | AWS 帳號建立時自動產生 | Root / IAM Admin 建立 |
| 權限 | 無限制（最高） | 由 Policy 控制 |
| 是否適合日常使用 | ❌ | ✅ |

---

## 四、最佳實務

- Root User：
  - 啟用 MFA
  - 建立 IAM Admin
  - 之後不再使用
- IAM User / Role：
  - 最小權限原則
  - 日常操作全部使用 IAM

---

## 五、一句話版本

> **Root User 是 AWS 帳號擁有者；  
> IAM User / Role 是實際操作資源的身份。**
