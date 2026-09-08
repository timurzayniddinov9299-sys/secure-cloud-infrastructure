# IAM Architecture

> **Holat:** Kod tayyorlangan, AWS resurslari hali real yaratilmagan.

## Maqsad

Har bir rol yoki xizmatga faqat o'z vazifasi uchun kerak bo'lgan minimal huquqlarni berish — **Principle of Least Privilege**.

## IAM arxitekturasi diagrammasi

```mermaid
flowchart TB
  subgraph TrustBoundary["Trust Boundary — AWS Account"]

    subgraph CISystem["CI/CD System (external)"]
      GHA["GitHub Actions\n(OIDC yoki IAM user)"]
    end

    subgraph Roles["IAM Roles"]
      InfraRole["infrastructure-role\nTrust: CI/CD ARN yoki account root"]
      WorkloadRole["workload-role\nTrust: ec2.amazonaws.com"]
      MonitoringRole["monitoring-role\nTrust: ec2.amazonaws.com"]
    end

    subgraph Policies["Customer-Managed Policies"]
      InfraPolicy["infrastructure-deploy-policy\n- ec2:Describe* → Resource:*\n- ec2:Create/Delete (network) → scoped ARN\n- cloudtrail:* → scoped ARN\n- s3:* (buckets) → scoped ARN\n- kms:* → scoped ARN\n- sns:* → scoped ARN"]
      WorkloadPolicy["workload-policy\n- logs:CreateLogGroup → account\n- logs:CreateLogStream/PutLogEvents → scoped\n- ssm:GetParameter → scoped"]
      MonitoringPolicy["monitoring-policy\n- logs:CreateLogGroup → account\n- logs:CreateLogStream/PutLogEvents → scoped\n- cloudwatch:PutMetricData → Resource:*"]
    end

    subgraph Resources["AWS Resources"]
      EC2Web["EC2: Web Server\n(keyingi bosqich)"]
      EC2App["EC2: App Server\n(keyingi bosqich)"]
      VPC["VPC / Subnets\n/ Security Groups"]
      CloudTrail["CloudTrail\n(hozir tayyor)"]
      S3Logs["S3 Log Bucket\n(hozir tayyor)"]
      KMS["KMS Key\n(hozir tayyor)"]
      CW["CloudWatch Logs\n(keyingi bosqich)"]
    end
  end

  GHA -->|sts:AssumeRole| InfraRole
  InfraRole --- InfraPolicy
  InfraPolicy -->|manage| VPC
  InfraPolicy -->|manage| CloudTrail
  InfraPolicy -->|manage| S3Logs
  InfraPolicy -->|manage| KMS

  EC2Web -->|sts:AssumeRole| WorkloadRole
  WorkloadRole --- WorkloadPolicy
  WorkloadPolicy -->|write logs| CW

  EC2App -->|sts:AssumeRole| MonitoringRole
  MonitoringRole --- MonitoringPolicy
  MonitoringPolicy -->|write metrics| CW

  style EC2Web stroke-dasharray:5 5,fill:#f9f9f9
  style EC2App stroke-dasharray:5 5,fill:#f9f9f9
  style CW stroke-dasharray:5 5,fill:#f9f9f9
```

## Rollar tavsifi

### Infrastructure Role
- **Maqsad:** Terraform/CI orqali tarmoq, IAM va logging resurslarini boshqarish
- **Trust:** CI/CD ARN yoki account root (fallback)
- **Cheklovi:** `AdministratorAccess` berilmagan; faqat zarur EC2/CloudTrail/S3/KMS amallar

### Workload Role
- **Maqsad:** EC2 web/application instanslari uchun
- **Trust:** `ec2.amazonaws.com`
- **Cheklovi:** Faqat CloudWatch Logs yozish va SSM Parameter o'qish

### Monitoring Role
- **Maqsad:** Monitoring/logging EC2 instanslari uchun
- **Trust:** `ec2.amazonaws.com`
- **Cheklovi:** Faqat CloudWatch Logs yozish va metrika publish qilish

## Wildcard ishlatilishi va asoslari

| Yerda | Nima | Sabab |
|---|---|---|
| `ec2:Describe*` → `Resource: "*"` | AWS API resource-level qo'llab-quvvatlamaydi | AWS xususiyati; scope imkoni yo'q |
| `cloudtrail:DescribeTrails` → `Resource: "*"` | AWS API resource-level qo'llab-quvvatlamaydi | AWS xususiyati |
| `kms:ListAliases` → `Resource: "*"` | AWS API resource-level qo'llab-quvvatlamaydi | AWS xususiyati |
| `cloudwatch:PutMetricData` → `Resource: "*"` | CloudWatch metrikalar hisobdan farq qilmaydi | AWS xususiyati |
| KMS key policy `kms:*` root ga | Account root kalit boshqaruvi uchun AWS talab qiladi | KMS standart talabi |

> **Qoida:** Barcha `Resource: "*"` holatlari AWS API cheklovlari tufayli majburiy va alohida izohlab qo'yilgan.

## Xavfsizlik tekshiruvlari

- ✅ `Action: "*"` ishlatilmagan hech bir yerda
- ✅ `Principal: "*"` ishlatilmagan trust policylarda
- ✅ Customer-managed policies (inline emas) — audit va versioning uchun
- ✅ `AdministratorAccess` biriktirilmagan
- ✅ Hardcoded credentials yo'q
- ✅ Checkov CKV_AWS_274, CKV2_AWS_40, CKV_AWS_61, CKV_AWS_60 — barchasidan o'tdi
