# Secure Cloud Infrastructure

[![Security CI/CD](https://github.com/timurzayniddinov9299-sys/secure-cloud-infrastructure/actions/workflows/security-pipeline.yml/badge.svg)](https://github.com/timurzayniddinov9299-sys/secure-cloud-infrastructure/actions/workflows/security-pipeline.yml)
[![Terraform](https://img.shields.io/badge/Terraform-1.15.8-844FBA?logo=terraform&logoColor=white)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-Cloud%20Security-FF9900?logo=amazon-aws&logoColor=white)](https://aws.amazon.com/)
[![Checkov](https://img.shields.io/badge/Checkov-3.3.18-2F80ED)](https://www.checkov.io/)
[![Python](https://img.shields.io/badge/Python-3.12-3776AB?logo=python&logoColor=white)](https://www.python.org/)

## Overview

This repository contains a security-focused AWS infrastructure implementation built with Terraform. It demonstrates defense-in-depth cloud security through network segmentation, least-privilege IAM, encryption, centralized audit logging, restricted network access, and automated DevSecOps validation.

The infrastructure is modular and designed as a secure foundation for cloud-hosted workloads.

## Architecture

```text
Internet
   |
   v
+-------------------+
| Internet Gateway  |
+---------+---------+
          |
          v
+-------------------------------+
| Public Subnets                |
| 10.0.1.0/24  10.0.2.0/24     |
|                               |
| Web Layer                     |
| TCP 80 / TCP 443              |
+---------------+---------------+
                |
          TCP 8080
                |
                v
+-------------------------------+
| Private Subnets               |
| 10.0.3.0/24  10.0.4.0/24     |
|                               |
| Application Layer             |
| App SG: Web SG -> TCP 8080   |
+-------------------------------+

Security and Audit Services
---------------------------
IAM        -> Least-privilege access
KMS        -> Encryption key management
S3        -> Encrypted CloudTrail log storage
CloudTrail -> AWS API activity auditing
SNS        -> Encrypted notifications
CI/CD      -> Automated security validation
```

Detailed architecture documentation:

- [Overall Architecture](diagrams/overall-architecture.md)
- [Network Architecture](diagrams/network-architecture.md)
- [IAM Architecture](diagrams/iam-architecture.md)
- [Logging and Encryption](diagrams/logging-encryption.md)

## Implemented Components

### Network

- VPC: `10.0.0.0/16`
- Public subnets:
  - `10.0.1.0/24`
  - `10.0.2.0/24`
- Private subnets:
  - `10.0.3.0/24`
  - `10.0.4.0/24`
- Availability Zones:
  - `eu-central-1a`
  - `eu-central-1b`
- Internet Gateway
- Dedicated public and private route tables

### Security Groups

**Web security group**
- Inbound TCP `80` from the internet
- Inbound TCP `443` from the internet
- Egress restricted to TCP `80` and `443`

**Application security group**
- Inbound TCP `8080` from the Web security group only
- Egress restricted to HTTPS

**Default security group**
- No inbound rules
- No outbound rules

SSH (`22`) and RDP (`3389`) are not exposed to the internet.

### IAM

The project defines dedicated roles for infrastructure management, workloads, and monitoring:

- `infrastructure-role`
- `workload-role`
- `monitoring-role`

Policies use resource-specific ARNs where AWS APIs support resource-level permissions. APIs that require `Resource = "*"` are documented accordingly.

### Encryption

- Customer-managed AWS KMS key
- Automatic key rotation
- 30-day KMS deletion window
- KMS integration with CloudTrail and SNS
- SSE-KMS encryption for CloudTrail log storage

### Logging and Alerting

- Multi-region AWS CloudTrail trail
- CloudTrail log-file validation
- Management event logging
- Encrypted and versioned S3 log bucket
- S3 Public Access Block
- HTTPS-only S3 access
- KMS-encrypted SNS topic with restricted publishing policy

## Security Controls

### Network Security

- Public/private subnet separation
- Application layer isolated from direct internet access
- Web access limited to HTTP/HTTPS
- Application access limited to Web security group
- Default security group locked down
- No public SSH or RDP access

### Identity and Access Management

- Least-privilege IAM policies
- Dedicated roles for infrastructure, workload, and monitoring use cases
- Resource-level IAM scoping where supported
- No broad administrative permissions for workload roles
- Documented `Resource = "*"` exceptions for AWS APIs that require them

### Data Protection

- KMS customer-managed encryption
- Automatic KMS key rotation
- SSE-KMS encrypted S3 logs
- S3 versioning
- S3 Public Access Block
- HTTPS-only access to the log bucket

### Audit and Monitoring

- Multi-region CloudTrail
- Log-file validation
- Centralized CloudTrail storage in S3
- Encrypted SNS notification channel
- Restricted CloudTrail/SNS policies

## Network Design

| Component | Configuration |
|---|---|
| VPC | `10.0.0.0/16` |
| Public Subnet 1 | `10.0.1.0/24` |
| Public Subnet 2 | `10.0.2.0/24` |
| Private Subnet 1 | `10.0.3.0/24` |
| Private Subnet 2 | `10.0.4.0/24` |
| Availability Zones | `eu-central-1a`, `eu-central-1b` |

### Routing

- Public subnets use the Internet Gateway for the default route.
- Private route tables contain local VPC routes only.
- NAT Gateway is intentionally not enabled in the current cost-conscious baseline.

### Security Group Relationships

| Security Group | Ingress | Egress |
|---|---|---|
| `web-sg` | Internet -> `80`, `443` | `80`, `443` |
| `app-sg` | `web-sg` -> `8080` | HTTPS |
| `default-sg` | None | None |

## IAM Design

### Roles

1. **Infrastructure role** — manages infrastructure and security resources required by Terraform.
2. **Workload role** — intended for web/application workloads.
3. **Monitoring role** — intended for monitoring and logging workloads.

### Least-Privilege Model

Where AWS supports resource-level permissions, policies reference specific resource ARNs.

For APIs such as certain EC2 `Describe*` operations that do not support resource-level permissions, `Resource = "*"` is used intentionally and documented in the Terraform policy.

## Logging and Monitoring

### CloudTrail

CloudTrail is configured with:

- Multi-region coverage
- Global service events
- Read/write management events
- Log-file validation
- KMS encryption
- Secure S3 delivery

### S3 Log Bucket

The log bucket uses:

- Versioning
- SSE-KMS encryption
- Public access blocking
- HTTPS-only transport
- Restricted CloudTrail write access

### SNS

The SNS topic:

- Uses KMS encryption
- Restricts publishing to CloudTrail
- Uses source validation conditions
- Provides the notification channel for CloudTrail-related alerts

## Security Validation / DevSecOps

Security validation is automated through:

```text
.github/workflows/security-pipeline.yml
```

The GitHub Actions pipeline includes:

1. **Terraform Format Check**
   - `terraform fmt -recursive -check`

2. **Terraform Validate**
   - `terraform init -backend=false`
   - `terraform validate`

3. **Checkov Security Scan**
   - Checkov `3.3.18`
   - Terraform security analysis

4. **Secret Scan**
   - `detect-secrets`
   - Checks for potential hardcoded credentials and secrets

5. **Security Tests**
   - `pytest tests/ -v --tb=short`

6. **Pipeline Summary**
   - Fails the workflow if a required security stage fails

### Latest Verified Results

| Validation | Result |
|---|---:|
| Terraform Format | PASS |
| Terraform Validate | PASS |
| Checkov | **92 passed / 0 failed / 11 skipped** |
| Secret Scan | PASS |
| Security Tests | **20 passed** |
| GitHub Actions | **PASS** |
| CI warnings | **0** |

## Testing

The test suite is located at:

```text
tests/test_security.py
```

It checks security properties of the Terraform configuration, including:

- Terraform formatting
- Terraform validation
- SSH/RDP exposure restrictions
- Security-group port restrictions
- S3 public-access protection
- S3 encryption
- S3 versioning
- IAM wildcard permissions
- Administrator access restrictions
- HTTPS enforcement
- KMS key rotation
- CloudTrail configuration
- Multi-region logging
- Log-file validation

The latest verified result is:

```text
20 passed
```

These tests validate the Terraform configuration and do not require AWS credentials.

## Repository Structure

```text
secure-cloud-infrastructure/
├── .github/
│   └── workflows/
│       └── security-pipeline.yml
├── diagrams/
│   ├── overall-architecture.md
│   ├── network-architecture.md
│   ├── iam-architecture.md
│   └── logging-encryption.md
├── docs/
│   ├── aws-cost-safety.md
│   ├── incident-response.md
│   ├── security-baseline.md
│   ├── security-testing.md
│   └── threat-model.md
├── modules/
│   ├── encryption/
│   ├── iam/
│   ├── logging/
│   ├── network/
│   └── security/
├── security/
│   └── reports/
├── terraform/
│   ├── main.tf
│   ├── outputs.tf
│   ├── providers.tf
│   ├── variables.tf
│   └── versions.tf
├── tests/
│   └── test_security.py
├── .gitignore
└── README.md
```

## Technologies

| Technology | Purpose |
|---|---|
| AWS | Cloud infrastructure and security services |
| Terraform `1.15.8` | Infrastructure as Code |
| AWS VPC | Network isolation and segmentation |
| AWS IAM | Identity and access management |
| AWS KMS | Encryption key management |
| Amazon S3 | Secure audit-log storage |
| AWS CloudTrail | API activity auditing |
| Amazon SNS | Notifications and alerting |
| GitHub Actions | CI/CD automation |
| Checkov `3.3.18` | Terraform security scanning |
| Python `3.12` | Security test automation |
| pytest | Automated testing |
| detect-secrets `1.5.0` | Secret scanning |

## Deployment / Usage

### Prerequisites

- Terraform `1.15.8`
- AWS CLI
- Appropriate AWS permissions
- Python environment for security tests

### Initialize

```bash
terraform -chdir=terraform init
```

### Validate

```bash
terraform -chdir=terraform validate
```

### Generate a Plan

```bash
terraform -chdir=terraform plan \
  -var="aws_region=eu-central-1" \
  -out=tfplan
```

Review the plan carefully before applying it.

### Apply

```bash
terraform -chdir=terraform apply tfplan
```

### Destroy

```bash
terraform -chdir=terraform destroy \
  -var="aws_region=eu-central-1"
```

## Security Notes

### AWS Credentials

Never commit:

- AWS access keys
- Secret keys
- API tokens
- Passwords
- `.env` files
- Sensitive `.tfvars` files

Use IAM roles, AWS CLI profiles, or GitHub Actions OIDC where appropriate.

### Terraform State

Terraform state may contain sensitive infrastructure information.

Do not commit:

```text
terraform.tfstate
terraform.tfstate.backup
```

The repository `.gitignore` excludes Terraform state and generated files.

For collaborative environments, use a remote state backend with appropriate locking.

### Before Applying Changes

Always inspect:

```bash
terraform -chdir=terraform plan -var="aws_region=eu-central-1"
```

before applying infrastructure changes.

## Future / Deferred Components

The current baseline intentionally leaves several workload and operational components outside the security foundation:

- NAT Gateway for controlled private-subnet internet egress
- EC2 workload instances
- Database layer such as Amazon RDS
- VPC Flow Logs
- Additional CloudWatch/SIEM integration
- S3 lifecycle and cross-region replication enhancements
- Remote Terraform state and locking
- GitHub Actions AWS OIDC deployment workflow

These can be introduced based on workload, operational, security, and cost requirements.

## Project Status

The project currently provides a modular AWS security-focused Terraform foundation.

Current verified status:

- Terraform formatting and validation pass
- Checkov: `92 passed / 0 failed / 11 skipped`
- Security tests: `20 passed`
- Secret scanning passes
- GitHub Actions pipeline passes with zero warnings
- Core infrastructure and security services have been provisioned and verified in AWS
- Workload resources such as EC2, NAT Gateway, and a database layer remain deferred

The repository is structured as a Cloud Security / DevSecOps portfolio project demonstrating Infrastructure as Code, security hardening, audit logging, and automated security validation.

## Additional Documentation

- [Security Baseline](docs/security-baseline.md)
- [Security Testing](docs/security-testing.md)
- [Threat Model](docs/threat-model.md)
- [Incident Response](docs/incident-response.md)
- [AWS Cost Safety](docs/aws-cost-safety.md)

## License

See the repository `LICENSE` file for licensing information.
