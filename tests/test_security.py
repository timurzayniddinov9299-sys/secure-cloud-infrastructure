"""
Secure Cloud Infrastructure — Security Tests

Terraform konfiguratsiyasini avtomatik tekshiruvchi testlar.
Bu testlar AWS credentialsiz, lokal kodga qarab ishlaydi.

Test kategoriyalari:
  1. Terraform format
  2. Terraform validate
  3. Forbidden ports (SSH/RDP internetga ochiq)
  4. Public S3 bloklash
  5. IAM wildcard Action/Principal
  6. HTTPS majburiy (insecure transport)
  7. KMS rotation
"""

import subprocess
import os
import re
import json
import pytest

# Loyiha asosiy papkasi
PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
TERRAFORM_DIR = os.path.join(PROJECT_ROOT, "terraform")
MODULES_DIR = os.path.join(PROJECT_ROOT, "modules")


def get_all_tf_files():
    """Barcha .tf fayllar ro'yxatini qaytaradi."""
    tf_files = []
    for root, dirs, files in os.walk(PROJECT_ROOT):
        # .terraform va .venv papkalarini o'tkazib yuborish
        dirs[:] = [
            d for d in dirs if d not in {".terraform", ".venv", ".git", "__pycache__"}
        ]
        for f in files:
            if f.endswith(".tf"):
                tf_files.append(os.path.join(root, f))
    return tf_files


def read_tf_file(path):
    """Terraform faylni o'qish."""
    with open(path, "r", encoding="utf-8") as f:
        return f.read()


def get_all_tf_content():
    """Barcha .tf fayllarning birlashtirilgan matnini qaytaradi."""
    return "\n".join(read_tf_file(f) for f in get_all_tf_files())


# ===========================================================================
# 1. Terraform Format
# ===========================================================================
class TestTerraformFormat:
    def test_terraform_fmt_check(self):
        """
        terraform fmt -recursive -check — barcha fayllar to'g'ri formatlanganini tekshiradi.
        Agar biror fayl noto'g'ri formatlangan bo'lsa — test FAIL.
        """
        result = subprocess.run(
            ["terraform", "fmt", "-recursive", "-check", PROJECT_ROOT],
            capture_output=True,
            text=True,
        )
        assert result.returncode == 0, (
            f"Terraform format muammosi topildi:\n{result.stdout}\n{result.stderr}\n"
            f"Tuzatish: `terraform fmt -recursive {PROJECT_ROOT}`"
        )


# ===========================================================================
# 2. Terraform Validate
# ===========================================================================
class TestTerraformValidate:
    def test_terraform_validate(self):
        """
        terraform validate — konfiguratsiya sintaktik va mantiqiy jihatdan to'g'riligini tekshiradi.
        terraform init -backend=false birinchi ishlashi kerak.
        """
        # Init
        init_result = subprocess.run(
            ["terraform", "init", "-backend=false"],
            capture_output=True,
            text=True,
            cwd=TERRAFORM_DIR,
        )
        assert init_result.returncode == 0, (
            f"terraform init muvaffaqiyatsiz:\n{init_result.stdout}\n{init_result.stderr}"
        )

        # Validate
        validate_result = subprocess.run(
            ["terraform", "validate"],
            capture_output=True,
            text=True,
            cwd=TERRAFORM_DIR,
        )
        assert validate_result.returncode == 0, (
            f"terraform validate muvaffaqiyatsiz:\n{validate_result.stdout}\n{validate_result.stderr}"
        )
        assert "Success" in validate_result.stdout or validate_result.returncode == 0


# ===========================================================================
# 3. Forbidden Ports — SSH/RDP internetga ochiq emas
# ===========================================================================
class TestForbiddenPorts:
    """
    Security Group konfiguratsiyasida SSH (22) va RDP (3389) portlari
    0.0.0.0/0 yoki ::/0 dan ochiq emasligi tekshiriladi.
    """

    FORBIDDEN_PATTERNS = [
        # SSH 22 + 0.0.0.0/0
        (r'from_port\s*=\s*22', r'cidr_blocks\s*=\s*\["0\.0\.0\.0/0"\]', "SSH port 22 internetga ochiq"),
        # RDP 3389 + 0.0.0.0/0
        (r'from_port\s*=\s*3389', r'cidr_blocks\s*=\s*\["0\.0\.0\.0/0"\]', "RDP port 3389 internetga ochiq"),
        # SSH IPv6
        (r'from_port\s*=\s*22', r'ipv6_cidr_blocks\s*=\s*\["::/0"\]', "SSH port 22 IPv6 internetga ochiq"),
    ]

    def _check_tf_file_for_port_pattern(self, content, port_pattern, cidr_pattern):
        """
        Fayl matnida port va CIDR birga kelishini tekshiradi.
        Bu soddalashtirilgan tekshiruv; Checkov kabi chuqur AST tahlil qilmaydi.
        """
        # ingress blokini topish
        ingress_blocks = re.findall(
            r'ingress\s*\{([^}]+)\}', content, re.DOTALL
        )
        for block in ingress_blocks:
            if re.search(port_pattern, block) and re.search(cidr_pattern, block):
                # checkov:skip bor-yo'qligini tekshirish
                # (suppress qilingan qoidalar hisobga olinmaydi)
                return True
        return False

    def test_no_ssh_from_internet(self):
        """SSH port 22 0.0.0.0/0 dan ochiq emasligi."""
        tf_files = get_all_tf_files()
        violations = []
        for tf_file in tf_files:
            content = read_tf_file(tf_file)
            if self._check_tf_file_for_port_pattern(
                content,
                r'from_port\s*=\s*22',
                r'cidr_blocks\s*=\s*\["0\.0\.0\.0/0"\]'
            ):
                violations.append(tf_file)
        assert not violations, (
            f"SSH port 22 internetga (0.0.0.0/0) ochiq topildi:\n" +
            "\n".join(violations)
        )

    def test_no_rdp_from_internet(self):
        """RDP port 3389 0.0.0.0/0 dan ochiq emasligi."""
        tf_files = get_all_tf_files()
        violations = []
        for tf_file in tf_files:
            content = read_tf_file(tf_file)
            if self._check_tf_file_for_port_pattern(
                content,
                r'from_port\s*=\s*3389',
                r'cidr_blocks\s*=\s*\["0\.0\.0\.0/0"\]'
            ):
                violations.append(tf_file)
        assert not violations, (
            f"RDP port 3389 internetga (0.0.0.0/0) ochiq topildi:\n" +
            "\n".join(violations)
        )

    def test_no_all_ports_from_internet(self):
        """from_port=0, to_port=0 (barcha portlar) + 0.0.0.0/0 kombinatsiyasi."""
        content = get_all_tf_content()
        # from_port=0, to_port=0, protocol=-1 (all traffic) + 0.0.0.0/0
        all_traffic_pattern = re.compile(
            r'ingress\s*\{[^}]*protocol\s*=\s*"-1"[^}]*cidr_blocks\s*=\s*\["0\.0\.0\.0/0"\][^}]*\}',
            re.DOTALL
        )
        matches = all_traffic_pattern.findall(content)
        assert not matches, (
            "Barcha portlar (-1/all) internetdan ochiq topildi! "
            "Bu qat'iyan taqiqlangan."
        )


# ===========================================================================
# 4. Public S3
# ===========================================================================
class TestPublicS3:
    """S3 bucket public access blokirovkasi tekshiriladi."""

    def test_no_public_s3_acl(self):
        """
        S3 bucket ACL public qilib qo'yilmagan — 'public-read' yoki 'public-read-write' yo'q.
        """
        tf_files = get_all_tf_files()
        violations = []
        for tf_file in tf_files:
            content = read_tf_file(tf_file)
            if re.search(r'acl\s*=\s*"public-read', content):
                violations.append(tf_file)
        assert not violations, (
            f"S3 public ACL topildi (public-read / public-read-write):\n" +
            "\n".join(violations)
        )

    def test_s3_public_access_block_present(self):
        """
        CloudTrail log bucket uchun aws_s3_bucket_public_access_block resurs mavjud.
        """
        tf_files = get_all_tf_files()
        pab_resources = []
        for tf_file in tf_files:
            content = read_tf_file(tf_file)
            if 'aws_s3_bucket_public_access_block' in content:
                pab_resources.append(tf_file)
        assert pab_resources, (
            "Hech qaysi .tf faylda aws_s3_bucket_public_access_block topilmadi! "
            "S3 bucket public access block bo'lishi SHART."
        )

    def test_s3_public_access_block_values(self):
        """
        aws_s3_bucket_public_access_block'da barcha 4 ta qiymat true bo'lishi kerak.
        """
        tf_files = get_all_tf_files()
        required_settings = [
            "block_public_acls",
            "block_public_policy",
            "ignore_public_acls",
            "restrict_public_buckets",
        ]
        for tf_file in tf_files:
            content = read_tf_file(tf_file)
            if 'aws_s3_bucket_public_access_block' not in content:
                continue
            for setting in required_settings:
                pattern = rf'{setting}\s*=\s*true'
                assert re.search(pattern, content), (
                    f"{tf_file}: {setting} = true topilmadi! "
                    f"aws_s3_bucket_public_access_block to'liq konfiguratsiya qilinishi kerak."
                )


# ===========================================================================
# 5. IAM wildcard tekshiruvi
# ===========================================================================
class TestIAMSecurity:
    """IAM policy'larda xavfli wildcardlar tekshiriladi."""

    def test_no_action_wildcard_in_policies(self):
        """
        IAM policylarda 'Action: "*"' ishlatilmagan.
        KMS key policy uchun root admin 'kms:*' istisno (bu KMS talabi).
        """
        tf_files = get_all_tf_files()
        violations = []
        for tf_file in tf_files:
            content = read_tf_file(tf_file)
            # 'Action = "*"' yoki '"Action": "*"' kombinatsiyasini qidirish
            # KMS root admin statement uchun 'kms:*' istisno
            # aws_iam_policy resurslarida tekshirish
            if 'aws_iam_policy' not in content:
                continue
            # "Action": "*" yoki Action = "*" patternlari
            if re.search(r'"Action"\s*:\s*"\*"', content) or \
               re.search(r'Action\s*=\s*"\*"', content):
                violations.append(tf_file)
        assert not violations, (
            f"IAM Policy'da Action: '*' (wildcard) topildi — TAQIQLANGAN:\n" +
            "\n".join(violations)
        )

    def test_no_principal_wildcard_in_trust_policies(self):
        """
        IAM rol trust policylarida 'Principal: "*"' ishlatilmagan.
        S3 bucket DenyInsecureTransport'dagi 'Principal: "*"' Deny effekt uchun istisno.
        """
        tf_files = get_all_tf_files()
        violations = []
        for tf_file in tf_files:
            content = read_tf_file(tf_file)
            # aws_iam_role trust policylarida Principal: "*" qidirish
            if 'aws_iam_role' not in content and 'assume_role_policy' not in content:
                continue
            # assume_role_policy blokida Principal: "*" qidirish
            assume_blocks = re.findall(
                r'assume_role_policy\s*=\s*jsonencode\s*\((.+?)\)\s*\)',
                content, re.DOTALL
            )
            for block in assume_blocks:
                if re.search(r'"Principal"\s*:\s*"\*"', block):
                    violations.append(tf_file)
        assert not violations, (
            f"IAM Trust Policy'da Principal: '*' topildi — XAVFLI:\n" +
            "\n".join(violations)
        )

    def test_no_administrator_access_policy(self):
        """AdministratorAccess managed policy biriktirilmagan."""
        content = get_all_tf_content()
        assert 'arn:aws:iam::aws:policy/AdministratorAccess' not in content, (
            "AdministratorAccess managed policy topildi — bu taqiqlangan!"
        )

    def test_no_inline_policies(self):
        """IAM inline policy ishlatilmagan (customer-managed tavsiya qilinadi)."""
        tf_files = get_all_tf_files()
        violations = []
        for tf_file in tf_files:
            content = read_tf_file(tf_file)
            # aws_iam_role_policy (inline) resurs bormi?
            if re.search(r'resource\s+"aws_iam_role_policy"', content):
                violations.append(tf_file)
        assert not violations, (
            f"aws_iam_role_policy (inline policy) topildi — customer-managed policy ishlatish tavsiya qilinadi:\n" +
            "\n".join(violations)
        )


# ===========================================================================
# 6. HTTPS / Insecure Transport
# ===========================================================================
class TestSecureTransport:
    """S3 bucket'larda HTTPS majburiyligi tekshiriladi."""

    def test_deny_insecure_transport_policy(self):
        """
        S3 bucket policyda DenyInsecureTransport yoki aws:SecureTransport=false blokirovkasi mavjud.
        """
        tf_files = get_all_tf_files()
        found = False
        for tf_file in tf_files:
            content = read_tf_file(tf_file)
            if 'aws:SecureTransport' in content and 'false' in content:
                found = True
                break
        assert found, (
            "Hech qaysi .tf faylda 'aws:SecureTransport'='false' Deny policy topilmadi! "
            "S3 bucket'lar HTTPS majburiy bo'lishi kerak."
        )

    def test_deny_insecure_effect_is_deny(self):
        """DenyInsecureTransport policyda Effect 'Deny' ekanligini tekshirish."""
        tf_files = get_all_tf_files()
        for tf_file in tf_files:
            content = read_tf_file(tf_file)
            if 'aws:SecureTransport' not in content:
                continue
            # SecureTransport borligiga qarab Deny effektini tekshirish
            secure_transport_sections = re.findall(
                r'(Effect[^}]+aws:SecureTransport[^}]+)', content, re.DOTALL
            )
            for section in secure_transport_sections:
                # Deny effekti bo'lishi shart
                assert 'Deny' in section or '"Deny"' in section, (
                    f"{tf_file}: aws:SecureTransport ishlatilgan, lekin Effect 'Deny' emas!"
                )


# ===========================================================================
# 7. KMS Rotation
# ===========================================================================
class TestKMSSecurity:
    """KMS kalit xavfsizlik konfiguratsiyasi."""

    def test_kms_rotation_enabled(self):
        """
        aws_kms_key RESOURCE ta'rifi bor fayllarda enable_key_rotation = true bo'lishi kerak.
        outputs.tf va boshqa fayllarda faqat reference sifatida turishi istisno.
        """
        tf_files = get_all_tf_files()
        kms_resource_files = []
        rotation_enabled = []
        for tf_file in tf_files:
            content = read_tf_file(tf_file)
            # Faqat resource "aws_kms_key" ta'rifini qidirish (reference emas)
            if re.search(r'resource\s+"aws_kms_key"', content):
                kms_resource_files.append(tf_file)
                if re.search(r'enable_key_rotation\s*=\s*true', content):
                    rotation_enabled.append(tf_file)
        assert kms_resource_files, "Hech qaysi .tf faylda aws_kms_key resource topilmadi!"
        assert len(kms_resource_files) == len(rotation_enabled), (
            f"Ba'zi KMS key resource fayllarida enable_key_rotation = true topilmadi!\n"
            f"KMS key resource fayllari: {kms_resource_files}\n"
            f"Rotation yoqilgan: {rotation_enabled}"
        )

    def test_kms_no_wildcard_principal(self):
        """
        KMS key policy'da Principal: '*' ishlatilmagan.
        Root admin uchun scoped ARN ishlatilishi kerak.
        """
        tf_files = get_all_tf_files()
        for tf_file in tf_files:
            content = read_tf_file(tf_file)
            if 'aws_kms_key' not in content:
                continue
            # KMS key policy blokini ajratib olish
            # va Principal: "*" qidirish
            # CloudTrail service principal wildcard emas, shuning uchun
            # faqat AWS principal "*" ni tekshirish
            kms_blocks = re.findall(
                r'resource\s+"aws_kms_key"[^{]*\{(.+?)^}',
                content, re.DOTALL | re.MULTILINE
            )
            for block in kms_blocks:
                # "Principal": "*" yoki Principal = "*"
                # Lekin cloudtrail.amazonaws.com service istisno
                aws_principal_wildcard = re.findall(
                    r'"AWS"\s*:\s*"\*"', block
                )
                assert not aws_principal_wildcard, (
                    f"{tf_file}: KMS key policy'da AWS Principal: '*' topildi — xavfli!"
                )


# ===========================================================================
# 8. CloudTrail
# ===========================================================================
class TestCloudTrail:
    """CloudTrail konfiguratsiya tekshiruvi."""

    def test_cloudtrail_exists(self):
        """aws_cloudtrail resurs mavjud."""
        content = get_all_tf_content()
        assert 'aws_cloudtrail' in content, (
            "aws_cloudtrail resurs topilmadi! CloudTrail konfiguratsiya qilinishi kerak."
        )

    def test_cloudtrail_log_validation_enabled(self):
        """enable_log_file_validation = true."""
        content = get_all_tf_content()
        assert re.search(r'enable_log_file_validation\s*=\s*true', content), (
            "CloudTrail log file validation yoqilmagan! "
            "enable_log_file_validation = true bo'lishi kerak."
        )

    def test_cloudtrail_multi_region(self):
        """is_multi_region_trail = true."""
        content = get_all_tf_content()
        assert re.search(r'is_multi_region_trail\s*=\s*true', content), (
            "CloudTrail multi-region yoqilmagan! "
            "is_multi_region_trail = true bo'lishi kerak."
        )

    def test_cloudtrail_encrypted_with_kms(self):
        """CloudTrail KMS bilan shifrlangan."""
        content = get_all_tf_content()
        # kms_key_id CloudTrail resursida
        ct_blocks = re.findall(
            r'resource\s+"aws_cloudtrail"[^{]*\{(.+?)^}',
            content, re.DOTALL | re.MULTILINE
        )
        for block in ct_blocks:
            assert 'kms_key_id' in block, (
                "aws_cloudtrail resursida kms_key_id topilmadi! "
                "CloudTrail KMS bilan shifrlangan bo'lishi kerak."
            )
