# Secure Cloud Infrastructure

Xavfsiz va tekshiriladigan bulut infratuzilmasi loyihasi. Loyiha AWS’da Terraform yordamida infratuzilmani kod orqali yaratish, uning xavfsizligini avtomatik tekshirish va GitHub Actions orqali CI/CD qilishni ko‘rsatadi.

> **Hozirgi holat:** BOSQICH 1 yakunlandi. AWS’da hali hech qanday resurs yaratilmagan.

## Loyiha maqsadi

Ishga kirish uchun kuchli Cloud Security / DevSecOps portfolioni yaratish: infratuzilmani kod sifatida boshqarish, xavfsizlikni avtomatik tekshirish, xatolarni aniqlash va tuzatish, barcha ishni GitHub orqali hujjatlashtirish.

## Muammo

Ko‘plab bulut infratuzilmalari qo‘lda yoki xavfsizlik nazoratisiz yaratiladi. Bu noto‘g‘ri ruxsatlar, ochiq portlar, shifrlanmagan ma'lumotlar va qayta tiklab bo‘lmaydigan muhitlarga olib keladi.

## Rejalashtirilgan yechim

Terraform yordamida infratuzilmani kod sifatida boshqarish. Asosiy yondashuvlar: minimal ruxsat, tarmoq segmentatsiyasi, ma'lumotlarni shifrlash, faoliyat jurnallari va avtomatik xavfsizlik tekshiruvlari.

## Texnologiyalar

- AWS
- Terraform
- Python
- Checkov (keyingi bosqichda)
- GitHub Actions
- Git

## Arxitektura

Hozircha faqat rejalashtirilgan arxitektura; resurslar hali yaratilmagan:

- Alohida VPC
- Public va private subnetlar
- Cheklangan kirish uchun bastion host
- Private subnetdagi ichki resurslar
- Security Groups va NACL
- IAM minimal ruxsat
- KMS yordamida shifrlash
- CloudTrail va VPC Flow Logs

Arxitektura diagrammasi keyingi bosqichda `diagrams/` papkasiga qo‘shiladi.

## Xavfsizlik tamoyillari

- Minimal ruxsat (least privilege)
- Internetga keraksiz port ochmaslik
- Maxfiy ma'lumotlarni kodga yozmaslik
- Saqlangan ma'lumotlarni shifrlash
- Faoliyatni jurnalga yozish
- Xavfsizlik sozlamalarini avtomatik tekshirish

## Loyiha tuzilmasi

```text
secure-cloud-infrastructure/
├── terraform/             # Terraform asosiy konfiguratsiyasi
├── modules/               # Qayta ishlatiladigan Terraform modullari
├── scripts/               # Avtomatlashtirish skriptlari
├── security/              # Xavfsizlik tekshiruvlari va siyosatlar
├── tests/                 # Testlar
├── diagrams/              # Arxitektura diagrammalari
├── docs/                  # Hujjatlar
├── .github/workflows/     # CI/CD ish oqimlari
├── README.md
└── .gitignore
```

## Tekshiruvlar

Hozirgi bosqichda quyidagilar tekshiriladi:

- `terraform fmt`
- `terraform init`
- `terraform validate`

Aniq natijalar buyruq chiqishi bilan yangilanadi.

## Keyingi bosqichlar

1. VPC va tarmoq segmentatsiyasi
2. IAM minimal ruxsat
3. Shifrlash va faoliyat jurnallari
4. Xavfsizlik tekshiruvlari
5. Ataylab xato + aniqlash + tuzatish
6. Avtomatik testlar
7. GitHub Actions
8. Professional portfolio yakuni
