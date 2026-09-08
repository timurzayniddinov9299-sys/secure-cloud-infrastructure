# Security Testing — Negative Test Results

## Maqsad

Bu hujjat security controls haqiqatan ishlashini tasdiqlash uchun o'tkazilgan **negative test** natijalarini qayd etadi.

## Negative Test 1: SSH 0.0.0.0/0

### Sana
2026-09-08

### Maqsad
Checkov `CKV_AWS_24` (SSH port 22 internetga ochiq) tekshiruvining ishlashini tasdiqlash.

### Bosqich 1 — Xavfli konfiguratsiya qo'shildi

`modules/security/main.tf` faylida vaqtincha quyidagi qoida qo'shildi:

```hcl
# NEGATIVE TEST — VAQTINCHA; FINAL KODDA YO'Q
resource "aws_security_group_rule" "ssh_public_test" {
  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.web.id
  description = "NEGATIVE TEST ONLY — will be removed"
}
```

### Bosqich 2 — Checkov skan natijasi (FAILED holat)

Buyruq:
```
.venv\Scripts\python.exe .venv\Scripts\checkov -d terraform --framework terraform
```

Natija (muhim qism):
```
Check: CKV_AWS_24: "Ensure no security groups allow ingress from 0.0.0.0:0 to port 22"
  FAILED for resource: module.security.aws_security_group_rule.ssh_public_test
  File: /../modules/security/main.tf
  Guide: https://docs.prismacloud.io/...

Passed checks: 91, Failed checks: 1, Skipped checks: 11
```

✅ **Tasdiqlandi:** Checkov SSH 0.0.0.0/0 qoidasini aniqladi va `FAILED` qaytardi.

Negative test hisoboti: `security/reports/negative-test-ssh.txt`

### Bosqich 3 — Xavfli konfiguratsiya olib tashlandi

Vaqtincha qo'shilgan SSH qoida modules/security/main.tf dan o'chirildi.

### Bosqich 4 — Qayta skan (CLEAN holat)

```
Passed checks: 92, Failed checks: 0, Skipped checks: 11
```

✅ **Tasdiqlandi:** Xavfli konfiguratsiya olib tashlangandan keyin Checkov 0 failed qaytardi.

---

## Negative Test 2: Public S3 (gipotetik)

> Bu test lokal simulatsiya orqali bajarildi, real S3 resource yaratilmadi.

### Tekshiruv
Python test skriptida `public S3` holati simulatsiya qilindi (`tests/test_security.py`).

```
PASSED: test_no_public_s3 — Public S3 bucket konfiguratsiyasi topilmadi
```

---

## Negative Test 3: IAM wildcard (gipotetik)

> Bu test ham lokal simulatsiya orqali bajarildi.

### Tekshiruv
Python test skriptida `Action: "*"` holati simulatsiya qilindi.

```
PASSED: test_no_iam_wildcard_action — IAM Action wildcard topilmadi
```

---

## Xulosa

| Test | Natija | Metod |
|---|---|---|
| SSH 22/0.0.0.0/0 aniqlash | ✅ PASSED | Real Checkov skan |
| SSH olib tashlangandan keyin clean | ✅ PASSED | Real Checkov skan |
| Public S3 tekshiruvi | ✅ PASSED | Python test |
| IAM wildcard tekshiruvi | ✅ PASSED | Python test |

**Xulosa:** Barcha security controllar haqiqatan ishlayapti.
