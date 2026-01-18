# 簡答題
1. root user 跟 iam user 的差別？
    - Root user 是帳號創建者的全權帳戶；無法被限制，應只用於必要帳務/安全操作。
    - IAM user 是可被授權的身分；權限可最小化、可分工、可審計。
2. user, group, role, policy 彼此間的關係為何？policy 的格式為何？

    - user / group / role / policy 關係
        - user：人或服務的長期身分，可有 access key / login。
        - group：一組 users 的權限集合；user 加入 group 會繼承其 policies。
        - role：可被「扮演」的身分，沒有長期密鑰；給 AWS 服務、跨帳號、臨時授權使用。
        - policy：權限規則；可附加到 user / group / role（身份型 policy）。
    - policy 格式（JSON）
        核心欄位：Version, Statement；Statement 內包含：

        - Effect: Allow / Deny
        - Action: 允許或拒絕的 API
        - Resource: 資源 ARN
        - Condition: 條件（選用）

        簡例：

            ```
                {
                    "Version": "2012-10-17",
                    "Statement": [
                        {
                            "Effect": "Allow",
                            "Action": "s3:ListBucket",
                            "Resource": "arn:aws:s3:::my-bucket"
                        }
                    ]
                }
            ```

# AWS IAM & Security Lab

## 1 – 為 Root Account 啟用 MFA

1. 使用 **Root user** 登入 AWS Console  
2. 右上角帳號 → **Security credentials**  
3. 找到 **Multi-factor authentication (MFA)**  
4. 點擊 **Assign MFA**  
5. 選擇：
   - `Authenticator app`（Google Authenticator / Authy / Microsoft Authenticator）
6. 掃描 QR Code，輸入連續兩組 6 碼驗證碼完成綁定  
7. 登出再登入，確認 root 登入時需要 MFA  

---

## 2 – 建立 Root 的 Credential 並使用 AWS CLI

1. 在 **Security credentials** 中建立 **Access Key（root）** and download
2. 本機安裝 AWS CLI -> ```brew update``` -> ```brew install awscli```
3. 設定 credential：

```bash
aws configure --profile root
# 輸入：
# AWS Access Key ID
# AWS Secret Access Key
# Region (ex: ap-northeast-1)
# Output format (json)
```

4. 確認有無建立
```
aws configure list(default) or aws configure list --profile root
- default
NAME       : VALUE                    : TYPE             : LOCATION
profile    : <not set>                : None             : None
access_key : ********************     : shared-credentials-file :
secret_key : ********************     : shared-credentials-file :
region     : ap-northeast-1           : config-file      : ~/.aws/config

- profile root
NAME       : VALUE                    : TYPE             : LOCATION
profile    : root                     : manual           : --profile
access_key : ****************WSGR     : shared-credentials-file :
secret_key : ****************L7Rv     : shared-credentials-file :
region     : ap-northeast-1           : config-file      : ~/.aws/config
```
configuration path:
 - ~/.aws/credentials
 - ~/.aws/config

> profile 設置為方便多個帳號角色切換

5. List ec2 and s3
- ```aws ec2 describe-instances --profile root```
- ```aws s3 ls --profile root```

## 3 – 建一個 user，名為 `s3_readonly`，並且僅給予其 s3 readonly 的權限，為此 user 創建 credential 並且設定在 aws 內，使用不同的 profile 可以指定用哪個 credential 跟 aws 溝通，驗證方式為嘗試取得 ec2 及 s3 的列表，其中一個會失敗。

### 網頁版

  建立 user + 權限

  1. 進 IAM Console → Users → Create user
  2. User name：s3_readonly
  3. Permissions：選 “Attach policies directly”
  4. 搜尋並勾選 AmazonS3ReadOnlyAccess
  5. Create user

  建立 access key

  1. 進入剛建立的 s3_readonly user
  2. Security credentials → Access keys → Create access key
  3. 用 “CLI” 類型 → Create
  4. aws configure list --profile s3_readonly 把 Access key / Secret key 帶入

  驗證
  1. 成功
  ```aws s3 ls --profile s3_readonly```

  2. 失敗（AccessDenied）
  ```aws ec2 describe-instances --profile s3_readonly```

  ### CLI
  流程與指令

  1. 建立 IAM user

        ```aws iam create-user --user-name s3_readonly --profile root```

  2. 附加 S3 ReadOnly 管理型政策
        ```
            aws iam attach-user-policy \
            --user-name s3_readonly \
            --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess \
            --profile root
        ```
  3. 建立 access key
        ```
            aws iam create-access-key --user-name s3_readonly --profile root
        ```  
      會輸出 AccessKeyId 和 SecretAccessKey。
  
  4. 把這組 credential 寫進新 profile（例如 s3_readonly）
        ```
            aws configure set aws_access_key_id <AccessKeyId> --profile s3_readonly
            aws configure set aws_secret_access_key <SecretAccessKey> --profile s3_readonly
            aws configure set region ap-northeast-1 --profile s3_readonly
            aws configure set output json --profile s3_readonly
        ```
  5. 驗證
        1. 成功
            ```aws s3 ls --profile s3_readonly```

        2. 失敗（AccessDenied）
            ```aws ec2 describe-instances --profile s3_readonly```

## 4 - 嘗試創建 inline policy，使 s3_readonly 這個使用者在某個時間後就無法存取 s3，並且回答 inline policy 可以用在哪些地方。
### 網頁版
在 Console 建 inline policy（給 s3_readonly）

  1. IAM → Users → s3_readonly
  2. Permissions → Add permissions → Create inline policy
  3. JSON 分頁貼上下面的 policy → Review → Create
        ```
        {
            "Version": "2012-10-17",
            "Statement": [
            {
                "Sid": "DenyS3AfterTime",
                "Effect": "Deny",
                "Action": "s3:*",
                "Resource": "*",
                "Condition": {
                "DateGreaterThan": {
                    "aws:CurrentTime": "2026-01-18T18:15:00Z"
                }
                }
            }
            ]
        }
        ```

### CLI
```
aws iam put-user-policy \
    --user-name s3_readonly \
    --policy-name s3_read_test \
    --policy-document '{
      "Version": "2012-10-17",
      "Statement": [
        {
          "Sid": "DenyS3AfterTime",
          "Effect": "Deny",
          "Action": "s3:*",
          "Resource": "*",
          "Condition": {
            "DateGreaterThan": {
              "aws:CurrentTime": "2026-01-18T18:15:00Z"
            }
          }
        }
      ]
    }' \
    --profile root
```

inline policy 可以用在三個地方：

  - IAM User
  - IAM Group
  - IAM Role

  用途是把客製化權限直接綁在特定主體上，不需要建立/共用管理型 policy。

  ## 5 - 嘗試創建 EC2，並且為其創建一個 S3ReadOnlyRole 的 role，使 ec2 上可以使用 aws cli（或是 sdk） 存取 s3 資源，並且不需要設定 access key。
  ### 網頁版 
  1 建立 IAM Role（給 EC2 用）

  1. 進 IAM → Roles → Create role
  2. Trusted entity 選 AWS service
  3. Use case 選 EC2
  4. Permissions 搜尋並勾選 AmazonS3ReadOnlyAccess
  5. Role name 填 S3ReadOnlyRole → Create role
     （這個角色會自動建立 instance profile，等會掛到 EC2）

  2 建立 EC2（Amazon Linux）並綁 Role

  1. 進 EC2 → Instances → Launch instances
  2. Name 隨意
  3. AMI 選 Amazon Linux
  4. Instance type 選 t2.micro 或 t3.micro
  5. Key pair 選你要的（或新建）
  6. Network 保持預設，Security group 至少開 22 (SSH)
  7. Advanced details → IAM instance profile → 選 S3ReadOnlyRole
  8. Launch

  3 連進 EC2 測試

  1. EC2 → 你的 instance → Connect
  2. 用 EC2 Instance Connect 或 SSH 連線 (如果用default security, 可去開myip 就可ssh 進去) like ```ssh -i "pem" ec2-user@ec2-00-000-00-00.ap-northeast-1.compute.amazonaws.com
  3. 在機器上跑： ```aws s3 ls```