# Security Baseline

Bu baseline loyihaning statik xavfsizlik holati uchun asosiy talablar ro'yxati.

## Holat: BOSQICH 9 — To'liq yakunlandi

**Sana:** 2026-09-08

---

## Talablar va holati

| Talab | Holat | Tekshiruv |
|---|---|---|
| Public S3 bucket yo'q | ✅ | `aws_s3_bucket_public_access_block` to'liq; Checkov CKV2_AWS_6 PASSED |
| Public SSH (22) yo'q | ✅ | Security Group 22/0.0.0.0/0 yo'q; Checkov CKV_AWS_24 PASSED |
| Public RDP (3389) yo'q | ✅ | Security Group 3389/0.0.0.0/0 yo'q; Checkov CKV_AWS_25 PASSED |
| Database portlari internetga ochilmagan | ✅ | DB SG keyingi bosqich; hozir DB port yo'q |
| S3 bucket encryption (SSE-KMS) | ✅ | `aws_s3_bucket_server_side_encryption_configuration`; Checkov CKV_AWS_145 PASSED |
| KMS rotation yoqilgan | ✅ | `enable_key_rotation = true`; Checkov CKV_AWS_7 PASSED |
| KMS kalit yoqilgan | ✅ | Checkov CKV_AWS_227 PASSED |
| KMS wildcard Principal yo'q | ✅ | Checkov CKV_AWS_33 PASSED |
| CloudTrail yoqilgan | ✅ | `aws_cloudtrail.this` resource mavjud |
| CloudTrail multi-region | ✅ | `is_multi_region_trail = true` |
| CloudTrail log validation | ✅ | `enable_log_file_validation = true` |
| HTTPS majburiy (S3) | ✅ | Bucket policy `DenyInsecureTransport` |
| Least privilege IAM | ✅ | `Action:*` ishlatilmagan; scoped ARN; Checkov CKV2_AWS_40 PASSED |
| Hardcoded secret yo'q | ✅ | Secret scan o'tdi; `.gitignore` da `.env` va `*.tfvars` |
| IAM AdministratorAccess yo'q | ✅ | Checkov CKV_AWS_274 PASSED |
| Default Security Group bloklangan | ✅ | `aws_default_security_group` — ingress/egress bo'sh |
| S3 versioning yoqilgan | ✅ | `aws_s3_bucket_versioning` Enabled; Checkov CKV_AWS_21 PASSED |

---

## Yakuniy Checkov natijasi (BOSQICH 9)

```
Passed checks: 92
Failed checks: 0
Skipped checks: 11 (barchasining sababi hujjatlashtirilgan)
```

### Skipped tekshiruvlar va sabablari

| Check ID | Sabab |
|---|---|
| CKV_AWS_130 | Public subnetlar ataylab public IP olishi kerak (web layer) |
| CKV_AWS_260 | Web qatlam internetdan HTTP/HTTPS qabul qilishi shart |
| CKV2_AWS_5 (x2) | Hali EC2 resursi yo'q; SG keyingi bosqichda biriktiriladi |
| CKV2_AWS_11 | VPC Flow Logs keyingi network revisionga qoldirildi |
| CKV2_AWS_10 | CloudTrail→S3 asosiy; CloudWatch Logs integratsiyasi keyinga |
| CKV2_AWS_62 | S3 event notifications CloudTrail log bucket uchun kerak emas |
| CKV_AWS_18 | Alohida access logging CloudTrail log bucket uchun kerak emas |
| CKV_AWS_144 | Cross-region replication xarajat sabab keyinga qoldirildi |
| CKV2_AWS_61 | Lifecycle konfiguratsiya storage policy bilan birgalikda qo'shiladi |

---

## Negative test natijasi

- Vaqtincha `SSH 0.0.0.0/0` qoidasi qo'shildi
- Checkov `CKV_AWS_24` ni aniqladi (FAILED)
- Qoida olib tashlandi
- Qayta skan: `0 failed`

Batafsil: [docs/security-testing.md](security-testing.md)

---

## Tekshiruv metodologiyasi

1. **Checkov** — statik kod tahlil (SAST)
2. **terraform validate** — sintaksis va mantiqiy tekshiruv
3. **terraform fmt -check** — format tekshiruv
4. **Secret scan** — credential leak tekshiruv
5. **Negative test** — security control ishlashi tasdiqlandi

---

## Kelajakdagi baseline yangilanishlari

Quyidagilar qo'shilganda baseline yangilanadi:

- VPC Flow Logs yoqilganda
- CloudWatch Logs integratsiyasi qo'shilganda
- AWS deploy amalga oshirilganda (AWS Config, Security Hub)
- Database qatlam qo'shilganda
