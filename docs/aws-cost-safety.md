# AWS Cost Safety Guide

> **Maqsad:** AWS'ga deploy qilishdan oldin qaysi resurslar xarajat keltirishi va qanday nazorat qilish mumkinligini tushuntirish.

## Muhim eslatma

Bu hujjatdagi narxlar taxminiy emas. Aniq va joriy narxlar uchun [AWS Pricing Calculator](https://calculator.aws/pricing/2/home) dan foydalaning.

---

## Loyihada bo'lgan pullik resurslar

### 1. NAT Gateway
- **Holat:** Hozircha kodga kiritilmagan (keyingi bosqich)
- **Xarajat:** Soatlik to'lov + GB uchun to'lov
- **Nazorat:** Kerak bo'lganda qo'shing; test muhitida o'chiring
- **Muqobil:** AWS PrivateLink yoki SSM endpoint (ba'zi hollarda arzonroq)

### 2. KMS Customer-Managed Key (CMK)
- **Holat:** ✅ Kodda mavjud (`modules/encryption/`)
- **Xarajat:** Oy uchun nominal to'lov + API chaqiruvlar uchun
- **Nazorat:** Foydalanilmagan keylarni o'chiring (30-kun oynasi); alias tekshiring

### 3. CloudTrail
- **Holat:** ✅ Kodda mavjud (`modules/logging/`)
- **Xarajat:** Management events uchun birinchi trail bepul; qo'shimcha eventlar uchun to'lov
- **Nazorat:** `read_write_type` ni ehtiyotkorlik bilan tanlang; `All` eng ko'p ma'lumot beradi, lekin xarajati ham ko'p

### 4. S3 (Log bucket)
- **Holat:** ✅ Kodda mavjud (`modules/logging/`)
- **Xarajat:** Saqlash GB uchun + GET/PUT so'rovlari uchun
- **Nazorat:** S3 Lifecycle policy qo'shing (log fayllarni belgilangan vaqtdan keyin arxivlash yoki o'chirish)
- **Eslatma:** `CKV2_AWS_61` — lifecycle policy keyingi bosqichda qo'shiladi

### 5. EC2 (keyingi bosqich)
- **Holat:** ❌ Hozir kodda yo'q
- **Xarajat:** Instance turi va vaqtiga qarab
- **Nazorat:** Test muhitida minimal instance turi ishlating; spot/reserved pricing tekshiring; ishlatilmaydigan vaqtda to'xtating

### 6. SNS (Alert topic)
- **Holat:** ✅ Kodda mavjud (`modules/logging/`)
- **Xarajat:** Juda kichik; publish/subscribe uchun nominal to'lov
- **Nazorat:** Subscription endpoint tekshiring

### 7. VPC (asosiy komponetlar)
- **IGW:** Bepul
- **Subnets:** Bepul
- **Route tables:** Bepul
- **VPC itself:** Bepul

---

## Xarajat nazorati uchun tavsiyalar

### Deploy oldin
1. **AWS Free Tier** tekshiring — yangi hisoblarda ko'p resurslar bepul (12 oy)
2. **AWS Budgets** sozlang — oylik budget va alert belgilang
3. **AWS Cost Explorer** yoqing — real-time xarajatlarni ko'ring

### Deploy vaqtida
```bash
# Terraform plan dan oldin to'liq tekshiring
terraform plan

# Faqat kerakli resurslarga apply qiling
terraform apply -target=module.network
```

### Deploy dan keyin
- CloudTrail → S3 da log hajmini kuzating
- KMS key API chaqiruvlarini CloudWatch bilan kuzating
- EC2 instance turini ehtiyotkorlik bilan tanlang

---

## "Bepul" bo'lib qolishi uchun

Hozirgi konfiguratsiya (NAT Gateway va EC2 siz) AWS'ga deploy qilinsa:

| Resurs | Bepul? |
|---|---|
| VPC, Subnets, IGW | ✅ Bepul |
| CloudTrail (birinchi trail, mgmt events) | ✅ Ko'pincha bepul |
| S3 (minimal hajm) | ⚠️ Hajmga qarab |
| KMS CMK | ⚠️ Nominal oylik to'lov |
| SNS | ✅ Minimal to'lov |
| **NAT Gateway** | ❌ **Doimo pullik** |
| **EC2** | ❌ **Pullik (Free Tier bilan bepul bo'lishi mumkin)** |

---

## Muhim: Xarajatlarni to'xtatish

AWS'ga deploy qilingandan keyin test/o'qish uchun:
```bash
# Barcha resurslarni o'chirish
terraform destroy

# Faqat muayyan modul
terraform destroy -target=module.logging
```

> ⚠️ **Ogohlantirish:** `terraform destroy` real resurslarni o'chiradi. S3 bucket'da ma'lumot bo'lsa, avval nusxa oling.
