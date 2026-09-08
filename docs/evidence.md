# Portfolio Dalillari va Xavfsizlik Verifikatsiyasi (Evidence)

Ushbu hujjat **Secure Cloud Infrastructure** loyihasi uchun amalga oshirilgan barcha lokal xavfsizlik, sintaksis, testlash va avtomatlashtirish tekshiruvlarining qat'iy dalillarini o'z ichiga oladi.

> **Eslatma:** AWS resurslari hali deploy qilinmagan. Barcha tekshiruvlar statik tahlil (SAST), politsiya auditlari va avtomatik testlar orqali amalga oshirilgan.

---

## 1. Terraform Format va Sintaktik Tekshiruv

### Buyruq
```bash
terraform fmt -recursive -check C:\secure-cloud-infrastructure
```
- **Maqsad:** Loyihadagi barcha `.tf` fayllar HCL2 standart formatiga to'liq mos kelishini tekshirish.
- **Natija:** 
  - Chiqish kodi: `0`
  - Hech qanday formatlash xatosi topilmadi (Clean).

---

## 2. Terraform Init va Validate

### Buyruqlar
```bash
cd C:\secure-cloud-infrastructure\terraform
terraform init -backend=false
terraform validate
```
- **Maqsad:** Terraform provayder va modullarini AWS hisobiga bog'lanmasdan initsializatsiya qilish, kod sintaksisi, o'zgaruvchilar va resurs argumentlarining mantiqiy to'g'riligini tekshirish.
- **Natija:**
  ```text
  Initializing modules...
  Initializing provider plugins...
  - Reusing previous version of hashicorp/aws from the dependency lock file
  - Using previously-installed hashicorp/aws v5.100.0

  Terraform has been successfully initialized!
  Success! The configuration is valid.
  ```
  - Chiqish kodi: `0`

---

## 3. Checkov SAST Xavfsizlik Auditi

### Buyruq
```bash
.venv\Scripts\python.exe .venv\Scripts\checkov -d terraform --framework terraform
```
- **Maqsad:** CIS AWS Foundations Benchmark, NIST va boshqa sanoat xavfsizlik standartlari bo'yicha Terraform kodini to'liq statik xavfsizlik skanidan o'tkazish.
- **Natija:**
  - **Passed checks:** `92`
  - **Failed checks:** `0` (CRITICAL = 0, HIGH = 0, MEDIUM = 0, LOW = 0)
  - **Skipped checks:** `11` (Barcha 11 ta skip qonuniy texnik asoslar bilan kod ichida izohlangan)
  - To'liq hisobot fayli: [`security/reports/latest-checkov.txt`](../security/reports/latest-checkov.txt)

---

## 4. Negative Security Test (Haqiqiy Tekshiruv Dalili)

### Maqsad
Xavfsizlik skanerlari haqiqatan ham xavfli qoidalarni aniqlay olishini isbotlash.

### Amalga oshirish bosqichlari:
1. `modules/security/main.tf` fayliga vaqtincha xavfli `SSH 22 / 0.0.0.0/0` qoidasi kiritildi.
2. Checkov skaner ishga tushirildi:
   ```text
   Check: CKV_AWS_24: "Ensure no security groups allow ingress from 0.0.0.0:0 to port 22"
   FAILED for resource: module.security.aws_security_group.negative_test_ssh
   Passed checks: 5, Failed checks: 1, Skipped checks: 0
   ```
   *Skaner muvaffaqiyatli tarzda 1 ta xatolikni aniqladi va jarayonni to'xtatdi.*
3. Xavfli SSH qoidasi darhol olib tashlandi.
4. Qayta tekshirildi: `0 failed`.

Batafsil ma'lumot: [`docs/security-testing.md`](security-testing.md) va hisobot: [`security/reports/negative-test-ssh.txt`](../security/reports/negative-test-ssh.txt).

---

## 5. Secret Leak Scanning (Maxfiy Ma'lumotlarni Skanlash)

### Buyruq
```bash
.venv\Scripts\detect-secrets.exe scan --exclude-files "\.terraform" --exclude-files "\.venv" --exclude-files "security\\reports" .
```
- **Maqsad:** Repozitoriyda AWS Access Key, Secret Key, token, parol yoki boshqa nozik ma'lumotlar bor-yo'qligini tekshirish.
- **Natija:**
  ```json
  {
    "results": {},
    "generated_at": "2026-09-08T06:39:15Z"
  }
  ```
  - `results: {}` — repozitoriy toza, hech qanday secret yoki token kodda mavjud emas.

---

## 6. Avtomatlashtirilgan Xavfsizlik Testlari (Pytest)

### Buyruq
```bash
.venv\Scripts\python.exe -m pytest tests/test_security.py -v --tb=short
```
- **Maqsad:** Terraform format, validate, taqiqlangan portlar (SSH 22, RDP 3389, -1/0), S3 public access, IAM wildcard Action/Principal, HTTPS majburiyligi, KMS rotatsiyasi va CloudTrail konfiguratsiyasini birlik va integratsiya darajasida tekshirish.
- **Natija:**
  ```text
  tests/test_security.py::TestTerraformFormat::test_terraform_fmt_check PASSED
  tests/test_security.py::TestTerraformValidate::test_terraform_validate PASSED
  tests/test_security.py::TestForbiddenPorts::test_no_ssh_from_internet PASSED
  tests/test_security.py::TestForbiddenPorts::test_no_rdp_from_internet PASSED
  tests/test_security.py::TestForbiddenPorts::test_no_all_ports_from_internet PASSED
  tests/test_security.py::TestPublicS3::test_no_public_s3_acl PASSED
  tests/test_security.py::TestPublicS3::test_s3_public_access_block_present PASSED
  tests/test_security.py::TestPublicS3::test_s3_public_access_block_values PASSED
  tests/test_security.py::TestIAMSecurity::test_no_action_wildcard_in_policies PASSED
  tests/test_security.py::TestIAMSecurity::test_no_principal_wildcard_in_trust_policies PASSED
  tests/test_security.py::TestIAMSecurity::test_no_administrator_access_policy PASSED
  tests/test_security.py::TestIAMSecurity::test_no_inline_policies PASSED
  tests/test_security.py::TestSecureTransport::test_deny_insecure_transport_policy PASSED
  tests/test_security.py::TestSecureTransport::test_deny_insecure_effect_is_deny PASSED
  tests/test_security.py::TestKMSSecurity::test_kms_rotation_enabled PASSED
  tests/test_security.py::TestKMSSecurity::test_kms_no_wildcard_principal PASSED
  tests/test_security.py::TestCloudTrail::test_cloudtrail_exists PASSED
  tests/test_security.py::TestCloudTrail::test_cloudtrail_log_validation_enabled PASSED
  tests/test_security.py::TestCloudTrail::test_cloudtrail_multi_region PASSED
  tests/test_security.py::TestCloudTrail::test_cloudtrail_encrypted_with_kms PASSED

  ============================= 20 passed in 3.19s ==============================
  ```
  - **20 ta testning barchasi 100% muvaffaqiyatli o'tdi.**

---

## 7. CI/CD GitHub Actions Pipeline

### Fayl
[`.github/workflows/security-pipeline.yml`](../.github/workflows/security-pipeline.yml)
- **Maqsad:** Har bir `push` va `pull_request` paytida inson omilisiz xavfsizlik nazoratini majburiy qilish.
- **Xususiyatlari:**
  - **Qat'iy Least Privilege:** Workflow va har bir alohida job darajasida faqat `permissions: contents: read` ruxsati berilgan, hech qanday ortiqcha write huquqlari yo'q.
  - **Immutable Commit SHA Pinning:** Barcha tashqi actionlar to'liq 40-belgili commit SHA orqali qulflangan (Supply Chain Security):
    - `actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4.2.2`
    - `hashicorp/setup-terraform@b9cd54a55928822304d9c490ccb872b7f5733d02 # v3.1.2`
    - `actions/setup-python@0b93645e9fea7318ecaed2b359559ac225c90a2b # v5.3.0`
    - `actions/upload-artifact@65c4c4a1ddee5b72f698fdd19549f0f0fb45cf08 # v4.6.0`
  - **Pipeline bloklash (Fail-closed):** Agar format, validate, Checkov (CRITICAL/HIGH), secret scan yoki pytest testlaridan biri yiqilsa, butun pipeline avtomatik to'xtatiladi.

---

## 8. Xavfsizlik Asosi (Security Baseline)

To'liq xavfsizlik talablari va ularning loyihadagi ijrosi [`docs/security-baseline.md`](security-baseline.md) hujjatida jamlangan. Asosiy ko'rsatkichlar:
- Public S3 = 0
- Public SSH = 0
- Public RDP = 0
- KMS Key Rotation = Enabled
- CloudTrail Multi-region + Integrity Validation = Enabled
- S3 HTTPS Enforced = Enabled
- Hardcoded Secret = 0
