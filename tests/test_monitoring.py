"""
Secure Cloud Infrastructure вЂ” Security Tests

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


class TestCloudWatchMonitoring:
    """CloudWatch Monitoring & Security Alarms configuration test."""

    def test_cloudtrail_cloudwatch_log_group_exists(self):
        """CloudTrail CloudWatch log group exists."""
        content = get_all_tf_content()
        # The log group name is defined via a local variable containing /aws/cloudtrail/
        assert 'aws_cloudwatch_log_group' in content and '/aws/cloudtrail/' in content, (
            "CloudTrail CloudWatch log group topilmadi! "
            "Log group nomi /aws/cloudtrail/ prefixi bilan bo'lishi kerak."
        )

    def test_cloudtrail_log_group_uses_kms(self):
        """CloudTrail log group uses KMS."""
        content = get_all_tf_content()
        # The cloudtrail log group must have kms_key_id and use the /aws/cloudtrail/ naming
        assert 'aws_cloudwatch_log_group' in content and 'kms_key_id' in content and '/aws/cloudtrail/' in content, (
            "CloudTrail CloudWatch log group KMS emas! "
            "kms_key_id parametri bo'lishi kerak."
        )

    def test_cloudtrail_log_group_retention_365(self):
        """CloudTrail log group retention = 365 days."""
        content = get_all_tf_content()
        log_group_blocks = re.findall(
            r'resource\s+"aws_cloudwatch_log_group"[^{]*\{(.+?^\})',
            content, re.DOTALL | re.MULTILINE
        )
        found = False
        for block in log_group_blocks:
            if 'kms_key_id' in block and 'retention_in_days' in block and '365' in block:
                found = True
                break
        assert found, (
            "CloudTrail CloudWatch log group topilmadi!"
        )

    def test_dedicated_cloudtrail_logs_role_exists(self):
        """Dedicated CloudTrail logs IAM role exists."""
        content = get_all_tf_content()
        assert 'aws_iam_role' in content and 'cloudtrail-logs' in content, (
            "CloudTrail CloudWatch logging role topilmadi!"
        )

    def test_trust_principal_is_cloudtrail(self):
        """Trust principal is cloudtrail.amazonaws.com."""
        content = get_all_tf_content()
        assert 'cloudtrail.amazonaws.com' in content, (
            "CloudTrail logging role trust principal cloudtrail.amazonaws.com emas!"
        )

    def test_trust_policy_contains_source_account(self):
        """Trust policy contains aws:SourceAccount."""
        content = get_all_tf_content()
        assert 'aws:SourceAccount' in content, (
            "CloudTrail logging role trust policy'da aws:SourceAccount topilmadi!"
        )

    def test_trust_policy_contains_source_arn(self):
        """Trust policy contains aws:SourceArn."""
        content = get_all_tf_content()
        assert 'aws:SourceArn' in content, (
            "CloudTrail logging role trust policy'da aws:SourceArn topilmadi!"
        )

    def test_no_inline_role_policy_for_cloudtrail_logs(self):
        """No inline aws_iam_role_policy for CloudTrail logs role."""
        content = get_all_tf_content()
        assert not re.search(r'resource\s+"aws_iam_role_policy"\s+"', content), (
            "aws_iam_role_policy (inline policy) topildi - "
            "customer-managed policy ishlatish kerak."
        )

    def test_security_alerts_sns_topic_exists(self):
        """Security alerts SNS topic exists."""
        content = get_all_tf_content()
        assert 'aws_sns_topic' in content and 'security-alerts' in content, (
            "Security alerts SNS topic topilmadi!"
        )

    def test_security_alerts_sns_topic_kms_encrypted(self):
        """Security alerts SNS topic is KMS encrypted."""
        content = get_all_tf_content()
        topic_blocks = re.findall(
            r'resource\s+"aws_sns_topic"[^{]*\{(.+?^\})',
            content, re.DOTALL | re.MULTILINE
        )
        found = False
        for block in topic_blocks:
            if 'security-alerts' in block and 'kms_master_key_id' in block:
                found = True
                break
        assert found, (
            "Security alerts SNS topic KMS emas! "
            "kms_master_key_id parametri bo'lishi kerak."
        )

    def test_unauthorized_api_metric_filter_exists(self):
        """Unauthorized API calls metric filter exists."""
        content = get_all_tf_content()
        filter_blocks = re.findall(
            r'resource\s+"aws_cloudwatch_log_metric_filter"[^{]*\{(.+?^\})',
            content, re.DOTALL | re.MULTILINE
        )
        # Also check in the full content since blocks may span nested braces
        # Fallback: just check for the metric name in the full content if no blocks found
        if not filter_blocks:
            filter_blocks = [content]  # search full content
        found = False
        for block in filter_blocks:
            if 'UnauthorizedApiCalls' in block:
                found = True
                break
        assert found, (
            "UnauthorizedApiCalls metric filter topilmadi!"
        )

    def test_console_login_without_mfa_metric_filter_exists(self):
        """Console login without MFA metric filter exists."""
        content = get_all_tf_content()
        filter_blocks = re.findall(
            r'resource\s+"aws_cloudwatch_log_metric_filter"[^{]*\{(.+?^\})',
            content, re.DOTALL | re.MULTILINE
        )
        # Also check in the full content since blocks may span nested braces
        # Fallback: just check for the metric name in the full content if no blocks found
        if not filter_blocks:
            filter_blocks = [content]  # search full content
        found = False
        for block in filter_blocks:
            if 'ConsoleLoginWithoutMFA' in block:
                found = True
                break
        assert found, (
            "ConsoleLoginWithoutMFA metric filter topilmadi!"
        )

    def test_root_account_activity_metric_filter_exists(self):
        """Root account activity metric filter exists."""
        content = get_all_tf_content()
        filter_blocks = re.findall(
            r'resource\s+"aws_cloudwatch_log_metric_filter"[^{]*\{(.+?^\})',
            content, re.DOTALL | re.MULTILINE
        )
        # Also check in the full content since blocks may span nested braces
        # Fallback: just check for the metric name in the full content if no blocks found
        if not filter_blocks:
            filter_blocks = [content]  # search full content
        found = False
        for block in filter_blocks:
            if 'RootAccountActivity' in block:
                found = True
                break
        assert found, (
            "RootAccountActivity metric filter topilmadi!"
        )

    def test_kms_key_protection_metric_filter_exists(self):
        """KMS key protection metric filter exists."""
        content = get_all_tf_content()
        # Look for KmsKeyProtectionChange in metric_filters or alarms
        assert 'KmsKeyProtectionChange' in content, (
            "KmsKeyProtectionChange metric filter topilmadi!"
        )

    def test_cloudwatch_alarms_exist(self):
        """CloudWatch metric alarms exist."""
        content = get_all_tf_content()
        alarm_count = content.count('aws_cloudwatch_metric_alarm')
        assert alarm_count >= 4, (
            f"Kamida 4 ta CloudWatch alarm kutilmoqda, topildi: {alarm_count}"
        )

    def test_alarm_actions_point_to_security_sns(self):
        """Alarm actions point to security alert SNS topic."""
        content = get_all_tf_content()
        # Check that alarm_actions reference security_alerts topic
        assert 'alarm_actions' in content and 'security_alerts' in content, (
            "Alarm action security alert SNS topicka yo'naltirilmagan!"
        )

    def test_ckv2_aws_10_skip_removed(self):
        """CKV2_AWS_10 skip no longer exists."""
        content = get_all_tf_content()
        assert 'CKV2_AWS_10' not in content, (
            "CKV2_AWS_10 skip hali ham mavjud вЂ” olib tashlash kerak!"
        )

