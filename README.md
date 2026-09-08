# Secure Cloud Infrastructure

Xavfsiz va tekshiriladigan bulut infratuzilmasi (Secure Cloud Infrastructure). Ushbu loyiha AWS bulut muhiti uchun Terraform yordamida infratuzilmani kod sifatida (Infrastructure as Code - IaC) boshqarish, ko'p qatlamli xavfsizlikni (Defense in Depth) ta'minlash, statik xavfsizlik tahlili (SAST/Checkov), avtomatlashtirilgan testlar va GitHub Actions CI/CD pipelineni amalga oshirishni professional darajada namoyish etadi.

---

## Loyiha maqsadi

Zamonaviy bulut tizimlarida xavfsizlik infratuzilma loyihalashning ilk bosqichlaridanoq ("Shift Left") kiritilishi shart. Loyihaning asosiy maqsadi:
- AWS bulutida xavfsizlik eng yuqori standartlarga (CIS AWS Foundations Benchmark, NIST) mos keladigan arxitektura qurish;
- Infratuzilmadagi xatoliklar, xavfli portlar va zaifliklarni ishlab chiqish bosqichida avtomatik aniqlash va bartaraf etish;
- DevSecOps madaniyatiga muvofiq, CI/CD quvurida xavfsizlik nazoratini inson omilisiz majburiy qilish;
- Cloud Security va DevSecOps yo'nalishida professional portfolio darajasidagi amaliy loyiha yaratish.

---

## Arxitektura

Loyiha ko'p qatlamli himoya (Defense-in-Depth) tamoyiliga asoslangan bo'lib, quyidagi mustaqil modullardan tashkil topgan:

```
Internet
   │
   ▼
Internet Gateway
   │
   ▼
Public Route Table → Public Subnet 1 & 2 (Web Layer)
   │  [Web Security Group: 80, 443 ochiq]
   │
   ▼ port 8080
Private Route Table → Private Subnet 1 & 2 (App Layer)
   │  [App Security Group: faqat Web SG dan 8080 ruxsat]
   │
   ▼ (keyingi bosqich)
Private Data Layer (Database)
```

Arxitektura diagrammalari:
- [Umumiy qatlamli arxitektura](diagrams/overall-architecture.md)
- [Tarmoq arxitekturasi](diagrams/network-architecture.md)
- [IAM rollar va siyosatlar](diagrams/iam-architecture.md)
- [Shifrlash va audit logging](diagrams/logging-encryption.md)

---

## Texnologiyalar

- **Cloud Platform:** Amazon Web Services (AWS)
- **Infrastructure as Code:** HashiCorp Terraform (v1.9+)
- **Security Scanner (SAST):** Checkov (v3.3+)
- **Secret Scanner:** detect-secrets (v1.5+)
- **Automated Testing:** Python 3.11+, Pytest
- **CI/CD:** GitHub Actions
- **Version Control:** Git

---

## Network Security

Tarmoq darajasidagi xavfsizlik segmentatsiyasi:
- **VPC Izolyatsiyasi:** `10.0.0.0/16` CIDR blokida 2 ta Availability Zone (AZ) bo'ylab tarqalgan alohida virtual tarmoq.
- **Subnetlar segmentatsiyasi:** 
  - 2 ta Public Subnet (`10.0.1.0/24`, `10.0.2.0/24`) — faqat tashqi trafik qabul qiluvchi resurslar uchun;
  - 2 ta Private Subnet (`10.0.3.0/24`, `10.0.4.0/24`) — ilova va ichki komponentlar uchun, internetdan bevosita ulanish imkoni yo'q.
- **Route Tables:** Public subnetlar Internet Gateway (IGW) orqali yo'naltirilgan, private subnetlar esa tashqi marshrutga ega emas.
- **Security Groups (SG):**
  - `web-sg`: Internetdan faqat 80 (HTTP) va 443 (HTTPS) portlariga ruxsat, egress faqat 80/443;
  - `app-sg`: Ingress faqat `web-sg`dan 8080 porti uchun, internetdan to'g'ridan-to'g'ri kirish mutlaqo bloklangan;
  - `default-sg`: VPC ning standart xavfsizlik guruhidagi barcha ingress va egress qoidalari qat'iy o'chirilgan (Blackhole).
- **Qat'iy taqiq:** SSH (22), RDP (3389) va boshqa barcha boshqaruv portlari internetga (0.0.0.0/0) ochilmagan.

---

## IAM Security

Identifikatsiya va ruxsatlarni boshqarishda eng kam huquq (Principle of Least Privilege) tamoyili:
- **Maxsus rollar:**
  - `infrastructure-role`: Faqat VPC, Subnet, Route Table, CloudTrail, KMS va S3 resurslarini boshqarish huquqiga ega. `AdministratorAccess` berilmagan;
  - `workload-role`: EC2 web/app serverlari uchun — faqat CloudWatch Logs yozish va SSM parametrlarni o'qish huquqi;
  - `monitoring-role`: Faqat CloudWatch Logs yozish va CloudWatch metrikalarini yuborish.
- **Wildcard siyosati:**
  - `Action: "*"` qat'iyan taqiqlangan;
  - `Resource: "*"` faqat AWS API resource-level cheklovlariga ega bo'lmagan amallar (masalan, `ec2:Describe*` yoki `cloudwatch:PutMetricData`) uchun asosli ravishda ishlatilgan;
  - `Principal: "*"` trust policylarda taqiqlangan.
- **Customer-Managed Policies:** Inline siyosatlardan voz kechilgan, barcha siyosatlar alohida versiyalanadi va audit qilinadi.

---

## Encryption

Ma'lumotlar saqlanish (At-Rest) va uzatilish (In-Transit) paytida to'liq shifrlanadi:
- **AWS KMS Customer-Managed Key (CMK):**
  - Avtomatik kalit aylanishi (`enable_key_rotation = true`) yoqilgan;
  - Tasodifiy o'chirishdan himoya sifatida 30 kunlik o'chirish oynasi (`deletion_window_in_days = 30`) belgilangan;
  - Key Policy faqat hisob root administratori va CloudTrail xizmatiga cheklangan kontekst asosida ruxsat beradi.
- **S3 Server-Side Encryption:** Barcha loglar SSE-KMS bilan mijoz kaliti orqali shifrlanadi.
- **In-Transit Encryption:** S3 bucket siyosatida `aws:SecureTransport: false` so'rovlariga `Deny` qoidasi qo'llangan — faqat HTTPS ruxsat etiladi.

---

## Logging

Audit va monitoring poydevori:
- **AWS CloudTrail:**
  - Ko'p mintaqali audit trail (`is_multi_region_trail = true`);
  - Barcha global xizmat eventlari qamrab olingan (`include_global_service_events = true`);
  - Barcha o'qish va yozish boshqaruv eventlari (`read_write_type = "All"`);
  - Log yaxlitligi tekshiruvi (`enable_log_file_validation = true`) orqali loglarning o'zgartirilmasligi (tamper-proof) ta'minlangan.
- **Secure Log Bucket (S3):**
  - S3 Public Access Block to'liq yoqilgan (4/4 parametr true);
  - S3 Versioning yoqilgan (tasodifiy yoki g'arazli o'chirishdan himoya);
  - Faqat CloudTrail xizmatiga o'ziga tegishli prefiksga yozish ruxsati berilgan;
  - Xavfsizlik xabarnomalari uchun KMS bilan shifrlangan SNS topic biriktirilgan.

---

## Security Scanning

Loyihada **Checkov** SAST vositasi orqali barcha Terraform kodlari statik xavfsizlik auditidan o'tkazilgan:
- **Tekshiruv natijasi:**
  - `92 passed`
  - `0 failed` (CRITICAL = 0, HIGH = 0, MEDIUM = 0, LOW = 0)
  - `11 skipped` (barchasi loyiha me'moriy qarorlari asosida kod ichida aniq izohlangan).
- **Maxfiy ma'lumotlarni skanlash:** `detect-secrets` vositasi yordamida repozitoriy to'liq tekshirildi — 0 ta secret/leak.
- To'liq hisobotlar: [`security/reports/latest-checkov.txt`](security/reports/latest-checkov.txt).

---

## DevSecOps Pipeline

GitHub Actions orqali to'liq avtomatlashtirilgan CI/CD pipeline:
- **Har bir Push va Pull Request'da avtomatik ishga tushadi:**
  1. **Terraform Format Check:** `terraform fmt -recursive -check`
  2. **Terraform Validate:** `terraform init -backend=false` va `terraform validate`
  3. **Checkov Security Scan:** SAST tekshiruv, CRITICAL yoki HIGH topilsa pipeline to'xtatiladi (`--hard-fail-on CRITICAL,HIGH`)
  4. **Secret Scanning:** Maxfiy kalit va parollarni qidirish (`detect-secrets`)
  5. **Automated Security Tests:** Pytest to'plami (20 ta avtomatik test)
- **Workflow Xavfsizligi:**
  - Qat'iy **Least Privilege**: workflow va barcha joblarda faqat `permissions: contents: read` ruxsati berilgan;
  - **Commit SHA Pinning**: Barcha tashqi GitHub Actions versiyalari to'liq 40-belgili commit SHA bilan qulflangan (Supply Chain xavfsizligi).

Batafsil: [`.github/workflows/security-pipeline.yml`](.github/workflows/security-pipeline.yml).

---

## Limitations

Hozirgi bosqichdagi texnik va me'moriy chegaralar:
- **AWS Real Resurslari:** AWS hisobida hali real resurslar (EC2, NAT Gateway, RDS) yaratilmagan, barcha tekshiruvlar statik kod tahlili va simulatsiya darajasida.
- **NAT Gateway:** Doimiy xarajat keltiruvchi komponent bo'lgani sababli, arxitekturaga kiritilgan lekin real deploy bosqichigacha faollashtirilmagan.
- **VPC Flow Logs va CloudWatch Logs Integratsiyasi:** Xarajat va keyingi Cloud SIEM bosqichiga qoldirilgan.
- **Terraform Remote State:** Hozirda lokal holatda, real deployment vaqtida S3 va DynamoDB locking bilan to'ldiriladi.
- **GitHub Actions Test Muhiti:** CI quvuri AWS credentialsiz, to'liq off-cloud rejimida xavfsizlik va sintaksis tekshiruvlarini o'tkazadi.

---

## Threat Model

Loyihaning ehtimoliy xavflari, hujum vektorlari va ularni bartaraf etish usullari STRIDE/NIST tamoyillari asosida tahlil qilingan:
- **Aktivlar:** VPC topologiyasi, IAM kalitlar, KMS kalitlari, CloudTrail audit loglari;
- **Asosiy xavflar:** Tarmoq xavflari (ochiq portlar, SG abuse), IAM haddan tashqari keng huquqlar, loglarni o'chirish/tampering, ma'lumotlar oqishi;
- **Boshqaruv choralari:** Har bir xavf uchun oldini olish (prevent), aniqlash (detect) va kamaytirish (mitigate) choralari ishlab chiqilgan.

To'liq hujjat: [`docs/threat-model.md`](docs/threat-model.md).

---

## Incident Response

Kelajakdagi real deployment va Cloud SIEM integratsiyasi uchun hodisalarga javob berish amaliyoti (Playbook) ishlab chiqilgan:
- Credential Compromise (AWS Key o'g'irlanishi) → Isolate → Preserve logs → Investigate → Remediate → Verify
- Security Group buzilishi (ochiq portlar)
- CloudTrail to'xtatilishi
- KMS kalit o'chirishga qo'yilishi
- S3 Public Access ochilishi

To'liq playbook: [`docs/incident-response.md`](docs/incident-response.md).

---

## Testing

Konfiguratsiyani avtomatik tekshiruvchi testlar `tests/test_security.py` ichida joylashgan:
- Format va sintaksis testlari;
- Taqiqlangan portlar (SSH 22, RDP 3389, 0.0.0.0/0 dan to'liq ochiq trafik);
- Public S3 va Public Access Block mavjudligi va qiymatlari;
- IAM wildcard `Action:*` va `Principal:*` mavjud emasligi;
- S3 HTTPS majburiyligi (`aws:SecureTransport`);
- KMS kalit rotatsiyasi va CloudTrail konfiguratsiyasi.

**Natija:** 20/20 test muvaffaqiyatli o'tdi (`pytest tests/ -v`).

Haqiqiy xavfsizlik nazorati ishlayotganini isbotlovchi **Negative Test** o'tkazilgan (vaqtincha SSH ochilib, Checkov uni topishi va olib tashlangach 0 failed holatiga qaytishi tasdiqlangan): [`docs/security-testing.md`](docs/security-testing.md).

---

## Security Baseline

Loyihaning yakuniy statik xavfsizlik asosi:
- [x] Public S3 bucket yo'q
- [x] Public SSH (22) yo'q
- [x] Public RDP (3389) yo'q
- [x] Database portlari internetga ochilmagan
- [x] S3 bucket encryption yoqilgan (SSE-KMS)
- [x] KMS rotation yoqilgan
- [x] CloudTrail yoqilgan va multi-region
- [x] CloudTrail log file validation yoqilgan
- [x] IAM least privilege saqlangan
- [x] Secure transport (HTTPS) majburiy
- [x] Maxfiy ma'lumotlar kodda mavjud emas

Batafsil: [`docs/security-baseline.md`](docs/security-baseline.md).

---

## Project Structure

```text
secure-cloud-infrastructure/
├── .github/
│   └── workflows/
│       └── security-pipeline.yml   # CI/CD GitHub Actions pipeline
├── diagrams/
│   ├── network-architecture.md    # Tarmoq arxitekturasi va SG oqimi
│   ├── iam-architecture.md        # IAM rollar, trust policy va huquqlar
│   ├── logging-encryption.md      # KMS, S3 va CloudTrail bog'liqligi
│   └── overall-architecture.md    # Umumiy qatlamli xavfsizlik diagrammasi
├── docs/
│   ├── aws-cost-safety.md         # AWS xarajat xavfsizligi va tavsiyalar
│   ├── evidence.md                # Barcha test va tekshiruvlar dalillari
│   ├── incident-response.md       # Hodisalarga javob berish bo'yicha qo'llanma
│   ├── security-baseline.md       # Xavfsizlik talablari va holati
│   ├── security-testing.md        # Negative test va testlash hisoboti
│   └── threat-model.md            # Xavflarni modellashtirish (Threat Model)
├── modules/
│   ├── encryption/                # KMS Customer-Managed Key va Alias
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── iam/                       # Minimal ruxsatli rollar va siyosatlar
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── logging/                   # CloudTrail, KMS bilan shifrlangan S3 va SNS
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── network/                   # VPC, Public/Private Subnetlar, IGW, Route Tables
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   └── security/                  # Web va App Security Groups
│       ├── main.tf
│       ├── outputs.tf
│       └── variables.tf
├── security/
│   └── reports/                   # Checkov va negative test hisobotlari
│       ├── checkov-bosqich9-final.txt
│       ├── latest-checkov.txt
│       └── negative-test-ssh.txt
├── tests/
│   └── test_security.py           # 20 ta avtomatlashtirilgan xavfsizlik testi
├── terraform/                     # Root Terraform konfiguratsiyasi
│   ├── main.tf
│   ├── outputs.tf
│   ├── providers.tf
│   ├── variables.tf
│   └── versions.tf
├── .gitignore
└── README.md
```

---

## Current Status

> **Current Status:**  
> **AWS deployment hali amalga oshirilmagan.**  
> Loyihaning barcha lokal, me'moriy, statik xavfsizlik, testlash, DevSecOps va hujjatlashtirish ishlari to'liq yakunlangan. Real AWS hisobida birorta ham resurs yaratilmagan, hisob xarajatlari xavfsiz holatda saqlangan.

---

## AWS Deployment Preparation

Kelajakda AWS hisob tayyor bo'lganda va real deploy bosqichiga o'tilganda bajariladigan ishlar:
1. **AWS Authentication & Setup:**
   - AWS CLI sozlash (`aws configure`) yoki CI/CD uchun AWS OIDC GitHub Actions integratsiyasini yoqish;
   - Terraform uchun masofaviy backend (S3 Bucket + DynamoDB State Locking) sozlash.
2. **Xarajat xavfsizligini ta'minlash:**
   - [`docs/aws-cost-safety.md`](docs/aws-cost-safety.md) bo'yicha AWS Budgets va Cost Alarms sozlash;
   - NAT Gateway va EC2 resurslarini faqat sinov davrida yoqish.
3. **Infratuzilmani rejalashtirish va qo'llash:**
   - `terraform plan -out=tfplan` orqali yaratiladigan resurslarni oldindan to'liq ko'rib chiqish;
   - `terraform apply tfplan` orqali resurslarni ketma-ketlikda yaratish.
4. **Deploydan keyingi tekshiruv:**
   - CloudTrail loglarining S3 ga shifrlanib tushayotganini tekshirish;
   - Log fayllari yaxlitligini tekshirish (`aws cloudtrail validate-logs`).
