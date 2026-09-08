# Network Architecture

> **Holat:** Kod tayyorlangan, AWS resurslari hali real yaratilmagan.

## Arxitektura tavsifi

Loyiha 2 ta availability zone'da quyidagi network arxitekturasini amalga oshiradi:

- **VPC** (`10.0.0.0/16`) — izolyatsiya qilingan tarmoq muhiti
- **Public subnetlar** (2x `/24`) — internet-facing resurslar uchun; Internet Gateway orqali tashqariga chiqadi
- **Private subnetlar** (2x `/24`) — ichki resurslar uchun; hozircha NAT Gateway yo'q
- **Internet Gateway** — public subnetlarga internet kirish
- **Route tables** — public (IGW marshruti bor), private (faqat lokal marshrutlar)
- **Default Security Group** — barcha ingress/egress bloklangan
- **Web Security Group** — 80/443 portlarini internetdan qabul qiladi
- **Application Security Group** — faqat Web SG'dan 8080 portida trafik qabul qiladi

## Traffic Flow

```
Internet
   │
   ▼
Internet Gateway
   │
   ▼
Public Route Table → Public Subnet 1 / Public Subnet 2
   │
   │  Web Server (Public Subnet ichida)
   │  [Web Security Group qoidalari qo'llanadi: 80/443 ruxsat]
   │
   ▼ port 8080
Application Server (Private Subnet ichida)
   │  [App Security Group qoidalari qo'llanadi: faqat Web SG dan 8080]
   │
   ▼
Data Layer (keyingi bosqich — Private Subnet)
   │  [DB Security Group: faqat App SG dan, DB porti]
```

## Security Group arxitekturasi

Security Group'lar resurslarning o'ziga emas, **resurslar o'rtasidagi trafikka qo'llanadigan qoidalar** sifatida ishlaydi:

| Security Group | Ingress | Egress | Maqsad |
|---|---|---|---|
| `web-sg` | 0.0.0.0/0 → 80, 443 | 80, 443 → 0.0.0.0/0 | Internet web trafigini qabul qilish |
| `app-sg` | web-sg → 8080 | 443 → 0.0.0.0/0 | Faqat web qatlamdan ilova trafigi |
| `default-sg` | (bo'sh) | (bo'sh) | Standart SG bloklangan |

> **Muhim:** Security Group'lar diagrammada subnet'lar orasida emas, balki resurslar ustiga qo'llanadigan **xavfsizlik qoidalari qatlami** sifatida ko'rsatilishi kerak.

## Mermaid diagramma

```mermaid
flowchart TB
  Internet((Internet))

  subgraph VPC["VPC — 10.0.0.0/16"]
    direction TB
    IGW["Internet Gateway"]
    pubRT["Public Route Table\n0.0.0.0/0 → IGW"]

    subgraph PublicTier["Public Tier (AZ-a / AZ-b)"]
      pub1["Public Subnet 1\n10.0.1.0/24 — AZ-a"]
      pub2["Public Subnet 2\n10.0.2.0/24 — AZ-b"]
    end

    subgraph WebSGBox["🔒 Web Security Group"]
      webRule["Ingress: 80/443 ← 0.0.0.0/0\nEgress: 80/443 → 0.0.0.0/0"]
    end

    subgraph PrivateTier["Private Tier (AZ-a / AZ-b)"]
      priv1["Private Subnet 1\n10.0.3.0/24 — AZ-a"]
      priv2["Private Subnet 2\n10.0.4.0/24 — AZ-b"]
    end

    subgraph AppSGBox["🔒 App Security Group"]
      appRule["Ingress: 8080 ← Web SG\nEgress: 443 → 0.0.0.0/0"]
    end

    dataLayer["⬜ Data Layer\n(keyingi bosqich)"]

    privRT1["Private Route Table 1\n(lokal only)"]
    privRT2["Private Route Table 2\n(lokal only)"]
  end

  Internet -->|HTTP/HTTPS| IGW
  IGW --> pubRT
  pubRT --> pub1
  pubRT --> pub2
  pub1 & pub2 -->|Web SG qoidalari| WebSGBox
  WebSGBox -->|port 8080| AppSGBox
  AppSGBox --> priv1
  AppSGBox --> priv2
  priv1 --> privRT1
  priv2 --> privRT2
  priv1 & priv2 -.->|keyingi bosqich| dataLayer

  style dataLayer stroke-dasharray: 5 5,fill:#f9f9f9
  style WebSGBox fill:#fff3cd,stroke:#ffc107
  style AppSGBox fill:#fff3cd,stroke:#ffc107
```

## Terraform fayllar

- [`modules/network/main.tf`](../modules/network/main.tf) — VPC, subnetlar, IGW, route tables
- [`modules/security/main.tf`](../modules/security/main.tf) — Security Groups

## Xavfsizlik qarorlari

| Muammo | Qaror |
|---|---|
| SSH (22) internetga ochiq | ❌ Hech qachon ruxsat berilmaydi |
| RDP (3389) internetga ochiq | ❌ Hech qachon ruxsat berilmaydi |
| DB portlari internetga ochiq | ❌ Faqat App SG dan |
| NAT Gateway | ⏳ Keyingi bosqich (xarajat sabab) |
| VPC Flow Logs | ⏳ Keyingi bosqich |
