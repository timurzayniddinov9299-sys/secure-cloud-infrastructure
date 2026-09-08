# Incident Response Playbook

> **Maqsad:** AWS deployment amalga oshirilganda samarali incident response uchun tayyorgarlik.
> Bu hujjat Cloud SIEM integratsiyasiga tayyorlash sifatida yaratilgan.

---

## Umumiy printsiplar

1. **Tezlik muhim** — dastlabki izolyatsiya, keyin tekshirish
2. **Hujjatlashtirish** — har bir amalni vaqt bilan qayd eting
3. **Zanjir saqlash** — forensic dalillarni o'zgartirmang
4. **Eskalatsiya** — shubhali holatlarda rahbariyatni xabardor qiling
5. **Qayta tiklanish** — tuzatishdan keyin verification

---

## Incident kategoriyalari

| Kategoriya | Misollar | Ustuvorlik |
|---|---|---|
| P1 — Kritik | Credential compromise, data breach, full account takeover | Darhol (≤15 daqiqa) |
| P2 — Yuqori | SG misconfiguration, KMS key deletion, CloudTrail stop | Tez (≤1 soat) |
| P3 — O'rta | IAM policy o'zgarishi, S3 public access | Normal (≤4 soat) |
| P4 — Past | Checkov failure, format issue | Keyingi ish kuni |

---

## IR-01: Credential Compromise (AWS Access Key)

### Belgilar
- AWS access key GitHub'da ko'rinib qoldi
- CloudTrail — noma'lum IP dan `sts:GetCallerIdentity` yoki boshqa amallar
- AWS anomaly detection xabardorligi

### Qadam 1: Izolyatsiya (≤5 daqiqa)
```bash
# Zarar etkazayotgan keyni darhol deactivate qiling
aws iam update-access-key \
  --access-key-id AKIAEXAMPLE \
  --status Inactive \
  --user-name USERNAME

# Sessiyalarni tugatish (agar role bo'lsa)
# Rol trust policyni yangilash yoki rolni o'chirish
```

### Qadam 2: Loglarni saqlash (≤10 daqiqa)
```bash
# CloudTrail eventlarini export qilish (so'nggi 24 soat)
aws cloudtrail lookup-events \
  --start-time $(date -d '24 hours ago' --iso-8601=seconds) \
  --output json > incident-$(date +%Y%m%d-%H%M%S).json

# Log fayl integrity tekshirish
aws cloudtrail validate-logs \
  --trail-arn arn:aws:cloudtrail:REGION:ACCOUNT:trail/TRAIL_NAME \
  --start-time $(date -d '7 days ago' --iso-8601=seconds)
```

### Qadam 3: Tekshirish (≤1 soat)
- [ ] Zarar etkazilgan key bilan qanday amallar bajarildi?
- [ ] Yangi IAM user/role/key yaratildimi?
- [ ] S3/RDS/EC2 resurslariga kirildimi?
- [ ] Xarajatlar anomaliyasi bormi? (AWS Cost Explorer)
- [ ] Boshqa regionlarda aktivlik bormi?

### Qadam 4: Tuzatish (≤2 soat)
```bash
# Zarar etkazilgan keyni o'chirish
aws iam delete-access-key \
  --access-key-id AKIAEXAMPLE \
  --user-name USERNAME

# Yangi key yaratish (zarur bo'lsa)
aws iam create-access-key --user-name USERNAME

# Shubhali amallar bilan yaratilgan resurslarni o'chirish
# (EC2, IAM user, S3 bucket va h.k.)
```

### Qadam 5: Verification
- [ ] Zarar etkazilgan key boshqa hech qayerda ishlatilmayapti
- [ ] Yangi key faqat zarur joyga kiritildi
- [ ] CloudTrail — keyingi 24 soat anomaliya yo'q

### Qadam 6: Post-mortem
- Qanday kiritildi? (hardcode, log, GitHub)
- `.gitignore` va secret scan qoidalari yangilandimi?
- Qachon bilinganidan qanchaga kirildi?

---

## IR-02: Security Group Misconfiguration (SSH/RDP public)

### Belgilar
- Checkov CI/CD da `CKV_AWS_24` (SSH) yoki `CKV_AWS_25` (RDP) xatoligi
- CloudTrail: `AuthorizeSecurityGroupIngress` — 0.0.0.0/0, port 22/3389

### Qadam 1: Izolyatsiya (≤5 daqiqa)
```bash
# SG qoidasini darhol olib tashlash
aws ec2 revoke-security-group-ingress \
  --group-id sg-XXXXXXXXX \
  --protocol tcp \
  --port 22 \
  --cidr 0.0.0.0/0
```

### Qadam 2: Tekshirish
```bash
# Kim qo'shdi?
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=AuthorizeSecurityGroupIngress \
  --start-time $(date -d '48 hours ago' --iso-8601=seconds)

# Ochiq port orqali kirishga urinish bormi?
# VPC Flow Logs (deploy vaqtida): reject/accept tekshirish
```

### Qadam 3: Tuzatish
- Terraform konfiguratsiyasiga bu qoidani kiritmaslik
- CI/CD da Checkov tekshiruvi muvaffaqiyatli o'tganligini tasdiqlash
- Agar haqiqiy SSH kerak bo'lsa: Bastion Host yoki SSM Session Manager

---

## IR-03: CloudTrail Stopped

### Belgilar
- CloudTrail `StopLogging` eventi
- SNS alert keldi
- Monitoring panelda loglar to'xtadi

### Qadam 1: Izolyatsiya va tiklash (≤5 daqiqa)
```bash
# CloudTrail ni qayta yoqish
aws cloudtrail start-logging \
  --name TRAIL_NAME
```

### Qadam 2: Tekshirish
```bash
# Kim to'xtatdi?
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=StopLogging

# Logging to'xtatilgan vaqt ichida nima bo'ldi?
# (Agar boshqa logging bor bo'lsa, masalan CloudWatch)
```

### Qadam 3: Tuzatish
- IAM policy review: `cloudtrail:StopLogging` ni kim ishlatishi mumkin?
- IAM Access Analyzer — keng ruxsat bormi?
- CloudWatch alarm qo'shish: `StopLogging` eventi → SNS

---

## IR-04: KMS Key Deletion Scheduled

### Belgilar
- CloudTrail `ScheduleKeyDeletion` eventi
- SNS alert

### Qadam 1: Darhol to'xtatish (≤5 daqiqa)
```bash
# Key o'chirishni bekor qilish (30-kun ichida imkon bor)
aws kms cancel-key-deletion \
  --key-id KEY_ID

# Key ni qayta yoqish
aws kms enable-key \
  --key-id KEY_ID
```

### Qadam 2: Tekshirish
- Kim `ScheduleKeyDeletion` buyrug'ini berdi?
- Tasodifiy yoki ataylab?
- KMS key bilan shifrlanган resourcelar ta'sirlandi?

### Qadam 3: Tuzatish
- IAM policy: `kms:ScheduleKeyDeletion` faqat senior engineer uchun
- Key deletion MFA require qilish (key policy)
- Alohida backup key (ko'p muhimlikdagi resurslar uchun)

---

## IR-05: S3 Public Access Block Removed

### Belgilar
- CloudTrail: `PutPublicAccessBlock` yoki `DeletePublicAccessBlock`
- Checkov / AWS Config: `CKV2_AWS_6` failed
- S3 bucket listing boshqa accountdan imkoni

### Qadam 1: Izolyatsiya (≤2 daqiqa)
```bash
# Public access block qayta yoqish
aws s3api put-public-access-block \
  --bucket BUCKET_NAME \
  --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,\
    BlockPublicPolicy=true,RestrictPublicBuckets=true
```

### Qadam 2: Tekshirish
- Bucket ma'lumotlariga kirildi?
- S3 access logs tekshirish
- Log fayl integrity: `validate-logs`

---

## Umumiy Incident Response chiziqli diagrammasi

```
Hodisa aniqlash
(CloudTrail, SNS, Checkov, monitoring)
    │
    ▼
Izolyatsiya
(SG revoke / key disable / bucket block / trail restart)
    │
    ▼
Loglarni saqlash
(CloudTrail export, validate-logs)
    │
    ▼
Tekshirish
(kim, qachon, nima, ta'sir)
    │
    ▼
Tuzatish
(noto'g'ri konfiguratsiyani to'g'rilash, rotatsiya)
    │
    ▼
Verification
(Checkov, CloudTrail — anomaliya yo'q)
    │
    ▼
Post-mortem
(sabab, jarayon yaxshilash, hujjatlashtirish)
```

---

## Foydali buyruqlar (Reference)

```bash
# CloudTrail so'nggi eventlar
aws cloudtrail lookup-events --max-items 50

# SG qoidalarini ko'rish
aws ec2 describe-security-groups --group-ids sg-XXXXX

# KMS key holati
aws kms describe-key --key-id KEY_ID

# S3 public access holati
aws s3api get-public-access-block --bucket BUCKET_NAME

# IAM role policies
aws iam list-attached-role-policies --role-name ROLE_NAME

# Active sessions (STS assumed roles)
aws sts get-caller-identity
```

---

## Cloud SIEM integratsiyasiga tayyorlik

Bu playbook keyingi bosqichda quyidagilar bilan boyitiladigan:

- **AWS Security Hub** — centralized security findings
- **Amazon GuardDuty** — ML-based threat detection
- **CloudWatch Alarms** — real-time metric alerting
- **SIEM integration** — Splunk/Elastic bilan CloudTrail eventlarni yuborish
- **Automated remediation** — Lambda functions bilan auto-response
