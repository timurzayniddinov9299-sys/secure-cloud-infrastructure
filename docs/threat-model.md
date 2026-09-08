# Threat Model

> **Holat:** Loyiha hali AWS'ga deploy qilinmagan. Bu threat model kelajakdagi deployment uchun tayyorlanmoqda.

## 1. Aktivlar (Assets)

| Aktiv | Tavsif | Muhimlik |
|---|---|---|
| VPC va tarmoq konfiguratsiyasi | Infratuzilma topologiyasi | Yuqori |
| IAM rollar va policies | Cloud access control | Kritik |
| KMS kalit material | Barcha shifrli ma'lumotlar kaliti | Kritik |
| CloudTrail loglar (S3) | Audit trail — kimdir nima qildi | Kritik |
| Web/App server kodi | Biznes mantig'i | Yuqori |
| Database (keyingi bosqich) | Foydalanuvchi ma'lumotlari | Kritik |
| Terraform state file | Infratuzilma haqiqiy holati | Kritik |
| GitHub/CI credentials | Deploy imkoniyati | Kritik |
| AWS credential | Account boshqaruvi | Kritik |

---

## 2. Mumkin bo'lgan hujumchilar (Threat Actors)

| Hujumchi | Imkoniyat | Motivatsiya |
|---|---|---|
| Tashqi hacker | Internetga ochiq portlar, zaif web | Ma'lumot o'g'irlash, cryptomining |
| Sabotajchi ichki foydalanuvchi | IAM access, repo kirish | Buzish, ma'lumot o'chirish |
| Supply chain hujumchisi | Terraform provider, dependency | Backdoor kiritish |
| Zararli CI/CD kod | Pull request, workflow | Secret o'g'irlash, deploy qilish |
| Credential o'g'irlagan hujumchi | AWS key leak, GitHub token | Account to'liq nazorat |

---

## 3. Asosiy xavflar

### T-01: Tarmoq xavflari (Network Threats)

#### T-01-1: Internet orqali bevosita kirish (VPC bypass)
- **Tavsif:** Hujumchi SSH (22) yoki RDP (3389) portini internetdan ochiq deb topadi
- **Oldini olish:** Security Group faqat 80/443 ruxsat; SSH/RDP hech qachon 0.0.0.0/0 ga ochilmaydi
- **Aniqlash:** Checkov CKV_AWS_24 (SSH), CKV_AWS_25 (RDP) tekshiruvlari; GitHub Actions har PR da ishlaydi
- **Kamaytirish:** Agar ochiq topilsa — SG qoidasini darhol olib tashlash; git blame bilan kim qo'shganini aniqlash

#### T-01-2: Security Group suiiste'moli (SG Abuse)
- **Tavsif:** Noto'g'ri konfiguratsiya bilan ommaviy ingress qoidasi qo'shiladi
- **Oldini olish:** Terraform IaC — qo'lda o'zgartirish taqiqlangan; IAM infra role faqat CI/CD uchun
- **Aniqlash:** CloudTrail `AuthorizeSecurityGroupIngress` eventi kuzatiladi
- **Kamaytirish:** Incident response: SG qoidasini revoke qilish; zararni baholash

#### T-01-3: Private subnetga to'g'ridan-to'g'ri kirish
- **Tavsif:** Private subnet resurslariga public internetdan kirish
- **Oldini olish:** Private subnetlar route table'da IGW marshruti yo'q; App SG faqat Web SG dan qabul qiladi
- **Aniqlash:** VPC Flow Logs (keyingi bosqich) → anomal trafik
- **Kamaytirish:** Network ACL bilan qo'shimcha bloklash

---

### T-02: IAM xavflari (Identity Threats)

#### T-02-1: Haddan tashqari keng permission
- **Tavsif:** IAM rol `AdministratorAccess` yoki `Action:*` bilan berilsa — to'liq account nazorat
- **Oldini olish:** Least privilege; Checkov CKV2_AWS_40 (full IAM privileges) tekshiruvi
- **Aniqlash:** IAM Access Analyzer; Checkov CI/CD da
- **Kamaytirish:** Rolni o'chirish yoki qayta yaratish; zararni baholash

#### T-02-2: Trust policy suiiste'moli (confused deputy)
- **Tavsif:** Trust policyda `Principal:*` yoki juda keng scope — ixtiyoriy principal role olishi mumkin
- **Oldini olish:** Trust policy faqat kerakli ARN/service ga; Checkov CKV_AWS_60, CKV_AWS_61
- **Aniqlash:** CloudTrail `AssumeRole` eventlari monitoring
- **Kamaytirish:** Trust policyni darhol cheklash; session kesmak

#### T-02-3: Inline policy orqali audit bypass
- **Tavsif:** Inline policy customer-managed policyga qaraganda audit qilish qiyinroq
- **Oldini olish:** Faqat customer-managed policies ishlatiladi; inline policy yo'q
- **Aniqlash:** IAM audit: `GetRolePolicy` — bo'sh bo'lishi kerak
- **Kamaytirish:** Topilgan inline policyni customer-managed ga ko'chirish

---

### T-03: Ma'lumot xavfsizligi (Data Security Threats)

#### T-03-1: KMS kalit yo'qolishi yoki bloklash
- **Tavsif:** KMS kalit o'chirilsa — barcha shifrli ma'lumotlar o'qib bo'lmaydi
- **Oldini olish:** `deletion_window_in_days = 30` — tasodifiy o'chirishdan himoya
- **Aniqlash:** CloudTrail `ScheduleKeyDeletion` eventi — SNS alert
- **Kamaytirish:** `CancelKeyDeletion` bilan to'xtatish; kalit policy audit

#### T-03-2: S3 bucket public qilib qo'yish
- **Tavsif:** Log bucket public access block olib tashlansa — loglar ochiq bo'ladi
- **Oldini olish:** `aws_s3_bucket_public_access_block` to'liq yoqilgan; Checkov CKV2_AWS_6
- **Aniqlash:** CloudTrail `PutBucketPublicAccessBlock` eventi; AWS Config (keyingi)
- **Kamaytirish:** Darhol public access block qayta yoqish; kim o'chirgani aniqlash

#### T-03-3: HTTP orqali trafik ushlab olish (man-in-the-middle)
- **Tavsif:** S3 ga HTTP so'rov yuborilsa — ma'lumot ochiq uzatiladi
- **Oldini olish:** Bucket policy `DenyInsecureTransport` — `aws:SecureTransport=false` so'rovlar rad etiladi
- **Aniqlash:** S3 access logs (keyingi bosqich)
- **Kamaytirish:** Policy allaqachon mavjud; vaqtincha olib tashlansa darhol qayta qo'shish

---

### T-04: Loglarni o'zgartirish (Log Tampering)

#### T-04-1: CloudTrail logini o'zgartirish
- **Tavsif:** Hujumchi iz qoldirmaslik uchun loglarni o'zgartirishi
- **Oldini olish:** `enable_log_file_validation = true` — SHA-256 digest fayllari
- **Aniqlash:** `aws cloudtrail validate-logs` buyrug'i bilan tekshirish
- **Kamaytirish:** Tamper aniqlanganda — forensic jarayon boshlash; digest fayllaridan o'zgartirish vaqtini aniqlash

#### T-04-2: CloudTrail o'chirib qo'yish
- **Tavsif:** `StopLogging` buyrug'i bilan audit logging to'xtatiladi
- **Oldini olish:** IAM policy `cloudtrail:StopLogging` faqat infra role ga; monitoring role ga berilmagan
- **Aniqlash:** CloudTrail o'zi `StopLogging` eventini qayd etadi; SNS alert
- **Kamaytirish:** `StartLogging` bilan qayta yoqish; policy review

#### T-04-3: S3 bucket versioning o'chirish
- **Tavsif:** Versioning o'chirilsa — log fayllari beiz o'chirilishi mumkin
- **Oldini olish:** `aws_s3_bucket_versioning` — `Enabled`; `PutBucketVersioning` faqat infra role
- **Aniqlash:** CloudTrail `PutBucketVersioning` eventi
- **Kamaytirish:** Versioning qayta yoqish; o'chirilgan versiyalarni baholash

---

### T-05: Credential Compromise

#### T-05-1: AWS Access Key leak (hardcoded)
- **Tavsif:** Kod ichiga yazilgan AWS access key GitHub'ga push qilinadi
- **Oldini olish:** `.gitignore` da `.env` va `*.tfvars` bloklangan; secret scan CI/CD da
- **Aniqlash:** GitHub secret scanning; trufflehog yoki detect-secrets CI da
- **Kamaytirish:** [Darhol] AWS key deactivate; CloudTrail — key bilan nima qilindi; yangi key yaratish

#### T-05-2: GitHub Actions token suiiste'moli
- **Tavsif:** `GITHUB_TOKEN` yoki custom secret workflow orqali o'g'irlanadi
- **Oldini olish:** Workflow minimal permissions (`contents: read`, `pull-requests: write`); pinned action versions
- **Aniqlash:** GitHub audit log; unexpected job runs
- **Kamaytirish:** Secret rotate; workflow review; PR approval requiriment

#### T-05-3: Terraform state file ichida credentials
- **Tavsif:** `terraform.tfstate` da sensitive qiymatlar saqlanishi mumkin
- **Oldini olish:** Backend konfiguratsiyasi hali yo'q (lokal state, `.gitignore`'da); deploy vaqtida remote backend (S3+KMS) ishlatiladi
- **Aniqlash:** `terraform show` chiqishini tekshirish; tfsec scan
- **Kamaytirish:** State file'ni remote backend'ga ko'chirish va KMS bilan shifrlash

---

## 4. Xavf matrisi

| Xavf ID | Tavsif | Ehtimollik | Ta'sir | Umumiy | Holat |
|---|---|---|---|---|---|
| T-01-1 | SSH/RDP internetga ochiq | Past (SG bloklangan) | Kritik | **O'rta** | ✅ Kamaytirish amalga oshirildi |
| T-01-2 | SG suiiste'moli | O'rta | Yuqori | **Yuqori** | ✅ IaC + CloudTrail |
| T-02-1 | Keng IAM permission | Past (checkov) | Kritik | **O'rta** | ✅ Kamaytirish amalga oshirildi |
| T-02-2 | Trust policy suiiste'moli | Past | Kritik | **O'rta** | ✅ Scoped trust policies |
| T-03-1 | KMS kalit yo'qolishi | Past | Kritik | **O'rta** | ✅ 30-kun oyna, alert |
| T-03-2 | S3 public | Past (PAB yoqilgan) | Yuqori | **Past** | ✅ Kamaytirish amalga oshirildi |
| T-04-1 | Log tampering | Past | Yuqori | **Past** | ✅ Log validation |
| T-04-2 | CloudTrail stop | O'rta | Kritik | **Yuqori** | ⚠️ Monitoring keyingi bosqich |
| T-05-1 | Credential leak | O'rta | Kritik | **Yuqori** | ✅ Secret scan + gitignore |
| T-05-2 | GHA token abuse | Past | Yuqori | **O'rta** | ✅ Minimal permissions + pinned |

---

## 5. Qolgan xavflar va yaxshilash yo'llari

| Tavsiya | Bosqich |
|---|---|
| VPC Flow Logs — tarmoq anomaliya aniqlash | Keyingi bosqich |
| CloudWatch alarm — CloudTrail stop eventi | Keyingi bosqich |
| AWS Config Rules — real-time compliance | Keyingi bosqich |
| Terraform state — S3+KMS remote backend | Deploy vaqtida |
| WAF — web application xavfsizligi | App deploy bosqichi |
| GuardDuty — ML-based anomaly detection | Keyingi bosqich |
