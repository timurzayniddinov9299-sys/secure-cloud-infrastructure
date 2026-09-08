# Overall Architecture

> **Holat:** Kod tayyorlangan, AWS resurslari hali real yaratilmagan.

## Layered Security Architecture

```mermaid
flowchart TB
  Internet((🌐 Internet))

  subgraph AWSCloud["AWS Cloud — us-east-1 (yoki boshqa region)"]

    subgraph NetworkLayer["Network Layer — VPC 10.0.0.0/16"]
      IGW["Internet Gateway"]
      pubRT["Public Route Table"]
      privRT["Private Route Table (lokal only)"]

      subgraph PublicZone["Public Zone (AZ-a, AZ-b)"]
        pub1["Public Subnet\n10.0.1.0/24"]
        pub2["Public Subnet\n10.0.2.0/24"]
        WebSG["🔒 Web SG\n80/443 ← Internet\nEgress: 80/443"]
      end

      subgraph PrivateZone["Private Zone (AZ-a, AZ-b)"]
        priv1["Private Subnet\n10.0.3.0/24"]
        priv2["Private Subnet\n10.0.4.0/24"]
        AppSG["🔒 App SG\n8080 ← Web SG\nEgress: 443"]
        DataLayer["⬜ Data Layer\n(keyingi bosqich)"]
        DataSG["⬜ DB SG\n(keyingi bosqich)"]
      end
    end

    subgraph IAMLayer["Identity & Access Management"]
      InfraRole["infrastructure-role\n(CI/CD deploy)"]
      WorkloadRole["workload-role\n(EC2 web/app)"]
      MonRole["monitoring-role\n(EC2 monitoring)"]
    end

    subgraph EncryptionLayer["Encryption Layer"]
      KMS["🔑 KMS CMK\nauto-rotation enabled"]
    end

    subgraph LoggingLayer["Audit & Logging Layer"]
      CT["☁ CloudTrail\nmulti-region, validated"]
      SNS["📢 SNS Alerts"]
      S3["🪣 S3 Log Bucket\nKMS encrypted, private\nHTTPS only, versioned"]
    end

    subgraph DefaultSG["Default Security Group"]
      DSG["Ingress: NONE\nEgress: NONE"]
    end
  end

  CI["🤖 CI/CD\n(GitHub Actions)"]

  Internet -->|HTTP/HTTPS| IGW
  IGW --> pubRT
  pubRT --> pub1
  pubRT --> pub2
  pub1 & pub2 --> WebSG
  WebSG -->|port 8080| AppSG
  AppSG --> priv1 & priv2
  priv1 & priv2 -.->|keyingi bosqich| DataLayer
  DataLayer -.-> DataSG

  CI -->|sts:AssumeRole| InfraRole
  InfraRole -->|manage| NetworkLayer

  KMS -->|encrypt logs| S3
  KMS -->|encrypt SNS| SNS
  CT -->|write logs| S3
  CT -->|alerts| SNS

  AWS_API(("AWS API Events")) -->|audit| CT

  style DataLayer stroke-dasharray:5 5,fill:#f9f9f9
  style DataSG stroke-dasharray:5 5,fill:#f9f9f9
  style DSG fill:#ffebee,stroke:#f44336
  style KMS fill:#fff3e0,stroke:#FF9800
  style S3 fill:#e8f5e9,stroke:#4CAF50
  style CT fill:#e8f4fd,stroke:#2196F3
```

## Xavfsizlik qatlamlari

| Qatlam | Texnologiya | Holat |
|---|---|---|
| **Network izolatsiya** | VPC, Public/Private Subnets | ✅ Tayyor |
| **Perimeter xavfsizligi** | Security Groups (web, app) | ✅ Tayyor |
| **Standart SG bloklash** | Default SG — ingress/egress yo'q | ✅ Tayyor |
| **Identity & Access** | IAM Roles + Least Privilege Policies | ✅ Tayyor |
| **Ma'lumot shifrlash** | KMS CMK + auto-rotation | ✅ Tayyor |
| **Audit logging** | CloudTrail multi-region + log validation | ✅ Tayyor |
| **Log xavfsizligi** | S3 KMS encrypted + HTTPS-only + versioned | ✅ Tayyor |
| **CI/CD xavfsizligi** | GitHub Actions + Checkov + secret scan | ✅ Tayyor |
| **VPC Flow Logs** | (NAT bilan birgalikda qo'shiladi) | ⏳ Keyingi bosqich |
| **WAF** | Web Application Firewall | ⏳ Keyingi bosqich |
| **Bastion Host** | SSH jump server | ⏳ Keyingi bosqich |

## Defense in Depth

```
Internet → [IGW] → [Route Table] → [Web SG: faqat 80/443]
                                         ↓
                                [Web Server: Public Subnet]
                                         ↓ port 8080
                               [App SG: faqat Web SG dan]
                                         ↓
                              [App Server: Private Subnet]
                                         ↓ DB port (keyingi)
                             [DB SG: faqat App SG dan]
                                         ↓
                                [Database: Private Subnet]

Parallel:
  All AWS API calls → [CloudTrail] → [KMS encrypt] → [S3 private bucket]
  IAM roles: minimal permissions, no wildcards
  KMS: CMK rotation enabled, scoped key policy
```
