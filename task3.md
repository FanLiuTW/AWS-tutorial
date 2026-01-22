# Task 3

【簡答題】

1) 何為 IaC? 除了 terraform 以外，還有哪些工具呢？
IaC 是用程式碼管理基礎設施。工具：CloudFormation、Pulumi、Ansible、Chef、Puppet、Salt、CDK、Bicep。

2) 執行 terraform 時，會有一個檔案 .tfstate，功能是什麼？
紀錄資源狀態與屬性，用來比對變更、計算 plan、做增量更新。

3) 多人協作時，如何確保 terraform 的狀態一致性？
用 remote backend（S3/GCS）+ lock（DynamoDB 等），避免同時寫入。

4) 何為冪等性？他在 IaC 工具中帶來怎樣的好處？
重複執行結果一致，不會重複建立/破壞資源；降低風險、方便自動化。

5) 何為 terraform module，它解決了什麼問題？
可重用的資源組合，解決重複、提升維護性與一致性。

6) terraform 的資源創建順序為何？如何去控制相依性？
依依賴圖排序（implicit/explicit）。用 `depends_on` 控制。

7) 何為 datasource?
讀取現有資源資訊（不建立），提供給其他資源使用。

8) 若使用 terraform 創建一台 ec2，希望對該 ec2 進行初始化操作，有哪些方式做到這件事，盡可能地列舉。
user_data、cloud-init、remote-exec + ssh、local-exec、SSM/RunCommand、AMI 預烘焙。
