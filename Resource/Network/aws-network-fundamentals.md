# AWS Network Fundamentals (Region → VPC → Subnet → Routing)

本文件完整說明 AWS 網路核心元件：

-   Region
-   Availability Zone (AZ)
-   VPC
-   Subnet
-   Route Table
-   Internet Gateway (IGW)
-   NAT Gateway
-   CIDR 的概念、計算與規劃方式
-   一個實際 EC2 網路架構範例（含外網 / 內網 / 內部服務通訊）

------------------------------------------------------------------------

## 1. Region（區域）

Region 是 AWS 在全球的實體區域，例如：

-   `us-east-1`（Virginia）
-   `ap-northeast-1`（Tokyo）
-   `eu-west-2`（London）

特性：

-   多數資源是 **Region Scoped**（EC2、VPC、RDS、ALB...）
-   不同 Region 之間完全隔離
-   成本、延遲、法規會因 Region 而異

------------------------------------------------------------------------

## 2. Availability Zone（AZ）

每個 Region 內包含多個 AZ，例如 `ap-northeast-1`：

-   ap-northeast-1a
-   ap-northeast-1c
-   ap-northeast-1d

特性：

-   每個 AZ 是獨立機房群
-   AZ 間低延遲、高頻寬
-   用於實現高可用（HA）

實務：

-   Subnet 必須屬於某一個 AZ
-   生產環境通常橫跨多個 AZ

------------------------------------------------------------------------

## 3. CIDR 是什麼？

前言
> IPv4 是目前最常見的網際網路協定，在IETF(Internet Engineering Task Force)於1981年9月發布的 RFC 791 中被描述最初的目的是讓全球的電腦彼此連接。它的地址由32位二進位數字組成，通常被分為4個「八位元組」或「位元組」，每個位元組由一個點分開，而每個位元組可以表示為0到255之間的數字。所以，IPv4地址的格式是：X.X.X.X，其中每個X都是0到255之間的數字。例如：192.149.252.76

CIDR（Classless Inter-Domain Routing）描述一段 IP 範圍：

表示法：
 - 格式：IP位址/前綴長度 (例如：192.168.0.0/16)。
 - /16表示IP位址的前16位是網路部分 (Network ID)，後面的位元是主機部分 (Host ID)。
 - 數字越大，網路部分越長，主機部分越短，表示這個網段越小。

``` text
10.0.0.0/16
```

意思是：

-   `10.0.0.0`：起始 IP
-   `/16`：前 16 個 bits 固定為網路位址
-   剩下 `32 - 16 = 16 bits` 給主機位址(32 是 因為)

可用 IP 數量：

``` text
2^(32 - 16) = 65,536
```

常見對照：
```
  CIDR   可用 IP 數
  ------ ------------
  /16    65,536
  /20    4,096
  /24    256
  /28    16
```

AWS 慣例：

-   VPC：`/16`
-   Subnet：`/24`

------------------------------------------------------------------------

## 4. VPC（Virtual Private Cloud）

VPC 是你在 AWS 上的「私有網路」。

建立時需指定 CIDR：

``` text
VPC: 10.0.0.0/16
```

特性：

-   你完全掌控 IP 規劃
-   自行定義 Subnet、Route Table
-   決定哪些資源能上網、哪些只能內部通訊

------------------------------------------------------------------------

## 5. Subnet

Subnet 是 VPC 的子網段，**必須綁定一個 AZ**。

範例：

  Subnet      AZ   CIDR          類型
  ----------- ---- ------------- ---------
  public-a    1a   10.0.1.0/24   Public
  private-a   1a   10.0.2.0/24   Private
  public-c    1c   10.0.3.0/24   Public
  private-c   1c   10.0.4.0/24   Private

是否為 Public / Private，取決於綁定的 Route Table。

------------------------------------------------------------------------

## 6. Route Table

Route Table 決定封包「要往哪裡走」。

### Public Route Table

``` text
Destination     Target
0.0.0.0/0       Internet Gateway
10.0.0.0/16     local
```

→ 綁定在 Public Subnet

### Private Route Table

``` text
Destination     Target
0.0.0.0/0       NAT Gateway
10.0.0.0/16     local
```

→ 綁定在 Private Subnet

------------------------------------------------------------------------

## 7. Internet Gateway（IGW）

-   VPC 對外的出口
-   讓 Public Subnet 中的資源能被 Internet 存取
-   Subnet Route Table 必須有：

``` text
0.0.0.0/0 → IGW
```

且 EC2 必須有 Public IP。

------------------------------------------------------------------------

## 8. NAT Gateway

NAT Gateway 用於：

> 讓 Private Subnet 內的資源「可以主動連外」，但「不能被外界連入」

特性：

-   NAT Gateway 本身必須放在 Public Subnet
-   Private Subnet Route Table：

``` text
0.0.0.0/0 → NAT Gateway
```

常見用途：

-   私有 EC2 更新套件
-   呼叫外部 API
-   不暴露在 Internet 上

------------------------------------------------------------------------

## 9. 實際 EC2 網路架構範例

設計：

-   Region：ap-northeast-1
-   VPC：10.0.0.0/16
-   Public Subnet：10.0.1.0/24
-   Private Subnet：10.0.2.0/24

元件：

-   Internet Gateway
-   NAT Gateway
-   Web EC2（Public）
-   App EC2（Private）

``` mermaid
flowchart LR
    Internet((Internet))

    subgraph AWS["AWS Region"]
        subgraph VPC["VPC 10.0.0.0/16"]

            IGW["Internet Gateway"]

            subgraph PublicSubnet["Public Subnet 10.0.1.0/24"]
                WebEC2["Web EC2(Public IP)"]
                NAT["NAT Gateway"]
            end

            subgraph PrivateSubnet["Private Subnet 10.0.2.0/24"]
                AppEC2["App EC2(Private)"]
            end
        end
    end

    Internet --> IGW --> WebEC2
    WebEC2 --> AppEC2
    AppEC2 --> NAT --> IGW --> Internet
```

Can see the pic from bytebytego: https://bytebytego.com/guides/typical-aws-network-architecture-in-one-diagram/

------------------------------------------------------------------------

## 10. 流量行為

  行為               路徑
  ------------------ --------------------------------
  使用者連線網站     Internet → IGW → Web EC2
  Web 呼叫內部服務   Web EC2 → App EC2
  App EC2 連外更新   App EC2 → NAT → IGW → Internet
  外部直連 App EC2   ❌（無 Public IP 與路由）

------------------------------------------------------------------------

這套模型是 AWS 生產環境最典型的網路設計基礎， 後續不論是
ALB、ECS、RDS、EKS，全部都建立在這個結構之上。
