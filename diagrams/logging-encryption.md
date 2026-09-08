# Encryption and Logging Architecture

> **Holat:** Kod tayyorlangan, AWS resurslari hali real yaratilmagan.

## Umumiy tavsif

Loyiha AWS KMS customer-managed kalit va CloudTrail yordamida barcha ma'lumotlarni shifrlaydi va faoliyatni jurnalga yozadi.

## To'liq arxitektura diagrammasi

```mermaid
flowchart TB
  subgraph AWSAccount["AWS Account"]

    subgraph KMSLayer["KMS Layer"]
      KMSKey["🔑 KMS Customer-Managed Key\nenable_key_rotation = true\ndeletion_window = 30 days"]
      KMSAlias["KMS Alias\nalias/secure-cloud-infra-dev-key"]
      KMSPolicy["Key Policy\n• root admin: kms:*\n• cloudtrail.amazonaws.com:\n  kms:GenerateDataKey*\n  kms:Decrypt (context-scoped)"]
    end

    subgraph CloudTrailLayer["CloudTrail Layer"]
      CT["☁ CloudTrail Trail\nis_multi_region_trail = true\ninclude_global_service_events = true\nenable_log_file_validation = true\nread_write_type = All"]
      SNSTopic["📢 SNS Alert Topic\n(KMS encrypted)"]
    end

    subgraph S3Layer["S3 Secure Log Storage"]
      S3Bucket["🪣 S3 Log Bucket\nprivate, versioned"]
      S3Enc["SSE-KMS Encryption\nkms_master_key_id → KMS key"]
      S3PAB["Public Access Block\nblock_public_acls = true\nblock_public_policy = true\nignore_public_acls = true\nrestrict_public_buckets = true"]
      S3Policy["Bucket Policy\n• AWSCloudTrailAclCheck: s3:GetBucketAcl\n• AWSCloudTrailWrite: s3:PutObject\n• DenyInsecureTransport: Deny s3:*\n  (aws:SecureTransport=false)"]
    end

    AWS_API["AWS API Events\n(management events)"]
    Admin["Account Administrator"]
  end

  AWS_API -->|generates events| CT
  CT -->|encrypted with KMS, writes logs| S3Bucket
  CT -->|alert| SNSTopic
  KMSKey -->|key material| KMSAlias
  KMSKey --- KMSPolicy
  KMSKey -->|encrypt/decrypt| S3Enc
  S3Enc --> S3Bucket
  S3PAB --> S3Bucket
  S3Policy --> S3Bucket
  Admin -->|manages| KMSKey

  style CT fill:#e8f4fd,stroke:#2196F3
  style KMSKey fill:#fff3e0,stroke:#FF9800
  style S3Bucket fill:#e8f5e9,stroke:#4CAF50
```

## KMS Key Policy — Least Privilege tahlili

### Root Administrator Statement
```json
{
  "Sid": "Enable account root administration",
  "Effect": "Allow",
  "Principal": { "AWS": "arn:aws:iam::ACCOUNT_ID:root" },
  "Action": "kms:*",
  "Resource": "*"
}
```
**Sabab:** AWS KMS talabi — hisob root'i kalit boshqaruvi uchun minimal zarur. Bu AWS standart tavsiyasi; bo'lmasa kalit bloklangan qolishi mumkin.

### CloudTrail Service Statement
```json
{
  "Sid": "Allow CloudTrail to use the key",
  "Effect": "Allow",
  "Principal": { "Service": "cloudtrail.amazonaws.com" },
  "Action": ["kms:GenerateDataKey*", "kms:Decrypt"],
  "Resource": "*",
  "Condition": {
    "StringLike": {
      "kms:EncryptionContext:aws:cloudtrail:arn": "arn:aws:cloudtrail:REGION:ACCOUNT:trail/NAME-*"
    }
  }
}
```
**Sabab:** Faqat `GenerateDataKey` va `Decrypt` — minimal kerakli. `Condition` bilan faqat bizning trail ARNiga cheklangan.

## CloudTrail xavfsizlik konfiguratsiyasi

| Sozlama | Qiymat | Maqsad |
|---|---|---|
| `is_multi_region_trail` | `true` | Barcha regionlardagi eventlarni qamrab olish |
| `include_global_service_events` | `true` | IAM, STS va boshqa global xizmatlar |
| `enable_log_file_validation` | `true` | Log fayllar o'zgartirilganini aniqlash |
| `kms_key_id` | customer-managed | Loglar shifrlanadi |
| `sns_topic_name` | alert topic | Hodisalar haqida bildirishnoma |
| `read_write_type` | `All` | Ham o'qish ham yozish eventlari |

## S3 Log Bucket xavfsizligi

| Xususiyat | Holat |
|---|---|
| Public Access Block (to'liq) | ✅ Yoqilgan (4/4 sozlama) |
| Versioning | ✅ Yoqilgan |
| Server-Side Encryption | ✅ SSE-KMS |
| HTTPS majburiy (DenyInsecureTransport) | ✅ Bucket Policy |
| Public ACL | ✅ Yo'q (private) |
| CloudTrail-only write | ✅ Bucket Policy bilan cheklangan |

## Terraform fayllar

- [`modules/encryption/main.tf`](../modules/encryption/main.tf) — KMS kalit va alias
- [`modules/encryption/variables.tf`](../modules/encryption/variables.tf) — o'zgaruvchilar
- [`modules/logging/main.tf`](../modules/logging/main.tf) — S3, CloudTrail, SNS, bucket policy
