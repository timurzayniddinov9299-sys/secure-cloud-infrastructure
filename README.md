Secure Cloud Infrastructure







Overview

This repository contains a security-focused AWS infrastructure implementation built with Terraform. It demonstrates defense-in-depth cloud security through network segmentation, least-privilege IAM, encryption, centralized audit logging, restricted network access, and automated DevSecOps validation.

The infrastructure is modular and is intended to provide a secure foundation for cloud-hosted workloads.

Objectives

Design a segmented AWS network with public and private subnets

Restrict network access through security groups

Apply least-privilege IAM policies

Protect data with AWS KMS and encrypted S3 storage

Centralize AWS API auditing with CloudTrail

Provide encrypted notification infrastructure through SNS

Detect Infrastructure as Code security issues with Checkov

Detect potential secrets before they are committed

Automatically validate infrastructure changes through GitHub Actions

Architecture

Internet
   |
   v
+-------------------+
| Internet Gateway  |
+---------+---------+
          |
          v
+--------------------------------+
| Public Subnets                 |
| 10.0.1.0/24  10.0.2.0/24      |
|                                |
| Web Layer                      |
| TCP 80 / TCP 443               |
+---------------+----------------+
                |
             TCP 8080
                |
                v
+--------------------------------+
| Private Subnets                |
| 10.0.3.0/24  10.0.4.0/24      |
|                                |
| Application Layer              |
| App SG: Web SG -> TCP 8080    |
+--------------------------------+

Security and Audit Services
---------------------------
IAM        -> Least-privilege access
KMS        -> Encryption key management
S3         -> Encrypted CloudTrail log storage
CloudTrail -> AWS API activity auditing
SNS        -> Encrypted notification infrastructure
CI/CD      -> Automated security validation

Detailed architecture documentation:

Overall Architecture

Network Architecture

IAM Architecture

Logging and Encryption

Implemented Components

Network

VPC: 10.0.0.0/16

Public subnets: 10.0.1.0/24, 10.0.2.0/24

Private subnets: 10.0.3.0/24, 10.0.4.0/24

Availability Zones: eu-central-1a, eu-central-1b

Internet Gateway

Dedicated public and private route tables

Security Groups

Web security group

Inbound TCP 80 from the internet

Inbound TCP 443 from the internet

Egress restricted to TCP 80 and 443

Application security group

Inbound TCP 8080 from the Web security group only

Egress restricted to HTTPS

Default security group

No inbound rules

No outbound rules

SSH (22) and RDP (3389) are not exposed to the internet.

IAM

The project defines dedicated roles for infrastructure management, workloads, and monitoring:

infrastructure-role

workload-role

monitoring-role

Policies use resource-specific ARNs where AWS APIs support resource-level permissions. APIs that require Resource = "*" are documented accordingly.

Encryption

Customer-managed AWS KMS key

Automatic key rotation

30-day KMS deletion window

KMS integration with CloudTrail and SNS

SSE-KMS encryption for CloudTrail log storage

Logging and Alerting

Multi-region AWS CloudTrail trail

CloudTrail log-file validation

Management event logging

Encrypted and versioned S3 log bucket

S3 Public Access Block

HTTPS-only S3 access

KMS-encrypted SNS topic with a restricted CloudTrail publishing policy

The SNS topic currently has no active subscriptions; the topic and publishing policy are configured, while an end-user delivery channel such as email, SQS, or Lambda remains a future integration.

Security Controls

Network Security

Public/private subnet separation

Application layer isolated from direct internet access

Web access limited to HTTP/HTTPS

Application access limited to the Web security group

Default security group locked down

No public SSH or RDP access

Identity and Access Management

Least-privilege IAM policies

Dedicated roles for infrastructure, workload, and monitoring use cases

Resource-level IAM scoping where supported

No broad administrative permissions for workload roles

Documented Resource = "*" exceptions for AWS APIs that require them

Data Protection

Customer-managed KMS encryption

Automatic KMS key rotation

SSE-KMS encrypted S3 logs

S3 versioning

S3 Public Access Block

HTTPS-only access to the log bucket

Audit and Monitoring

Multi-region CloudTrail

Log-file validation

Centralized CloudTrail storage in S3

KMS-encrypted SNS notification infrastructure

Restricted CloudTrail log-delivery and SNS publishing policies

Network Design

Component

Configuration

VPC

10.0.0.0/16

Public Subnet 1

10.0.1.0/24

Public Subnet 2

10.0.2.0/24

Private Subnet 1

10.0.3.0/24

Private Subnet 2

10.0.4.0/24

Availability Zones

eu-central-1a, eu-central-1b

Routing

Public subnets use the Internet Gateway for the default route.

Private route tables contain only local VPC routes.

NAT Gateway is intentionally not enabled in the current cost-conscious baseline.

Security Group Relationships

Security Group

Ingress

Egress

web-sg

Internet -> 80, 443

80, 443

app-sg

web-sg -> 8080

HTTPS

default-sg

None

None

IAM Design

Roles

Infrastructure role — manages infrastructure and security resources required by Terraform.

Workload role — intended for web/application workloads.

Monitoring role — intended for monitoring and logging workloads.

Least-Privilege Model

Where AWS supports resource-level permissions, policies reference specific resource ARNs.

For APIs such as certain EC2 Describe* operations that do not support resource-level permissions, Resource = "*" is used intentionally and documented in the policy.

Logging and Monitoring

CloudTrail

CloudTrail is configured with:

Multi-region coverage

Global service events

Read/write management events

Log-file validation

KMS encryption

Secure S3 delivery

S3 Log Bucket

The log bucket uses:

Versioning

SSE-KMS encryption

Public Access Block

HTTPS-only transport

Restricted CloudTrail write access

SNS

The SNS topic:

Uses KMS encryption

Restricts publishing to the CloudTrail trail

Uses source validation conditions

Provides the notification channel for CloudTrail-related events

AWS Setup

The project is designed to use AWS IAM Identity Center (AWS SSO) for local AWS CLI authentication instead of long-lived access keys. AWS recommends configuring IAM Identity Center profiles with aws configure sso and authenticating them with aws sso login.

Official AWS documentation: https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sso.html

1. Prerequisites

Install:

AWS CLI v2

Terraform 1.15.8

Python 3.12

You also need an AWS account with a least-privilege permission set that can manage the resources defined by this Terraform project and perform the required verification operations.

2. Configure an IAM Identity Center Profile

Run:

aws configure sso --profile cloud-security

The wizard asks for values such as:

SSO session name: <your-sso-session>
SSO start URL: <your-aws-access-portal-url>
SSO region: <your-iam-identity-center-region>
SSO registration scopes: sso:account:access

Then select the AWS account and permission set you want to use. Set the workload/default AWS Region to:

eu-central-1

The SSO region is the region that hosts IAM Identity Center; it may be different from the AWS workload region. citeturn506115search0

3. Sign in

aws sso login --profile cloud-security

If the cached SSO session expires, run the same command again to start a new session. citeturn506115search2

4. Verify the AWS Identity

aws sts get-caller-identity --profile cloud-security

5. Set the Profile for Terraform in PowerShell

$env:AWS_PROFILE = "cloud-security"
$env:AWS_DEFAULT_REGION = "eu-central-1"

Use the profile explicitly for AWS CLI commands when you want to avoid ambiguity:

aws sts get-caller-identity --profile cloud-security

6. Configure Terraform

From the repository root:

terraform -chdir=terraform init
terraform -chdir=terraform validate
terraform -chdir=terraform plan -var="aws_region=eu-central-1" -out=tfplan

Review the plan before applying changes:

terraform -chdir=terraform apply tfplan

The AWS CLI stores IAM Identity Center profile configuration in the user's AWS CLI config file; on Windows this is normally located at C:\Users\<USERNAME>\.aws\config. citeturn506115search5

Security Validation / DevSecOps

Security validation is automated through:

.github/workflows/security-pipeline.yml

The GitHub Actions pipeline includes:

Terraform Format Check — terraform fmt -recursive -check

Terraform Validate — terraform init -backend=false followed by terraform validate

Checkov Security Scan — Checkov 3.3.18

Secret Scan — detect-secrets

Security Tests — pytest tests/ -v --tb=short

Pipeline Summary — fails the workflow if a required stage fails

Latest Verified Results

Validation

Result

Terraform Format

PASS

Terraform Validate

PASS

Checkov

92 passed / 0 failed / 11 skipped

Secret Scan

PASS

Security Tests

20 passed

GitHub Actions

PASS

CI warnings

0

Real AWS Verification

The deployed AWS foundation was also verified directly through AWS CLI checks.

Verified controls include:

VPC and subnet topology

Public/private route separation

Web and application security groups

Locked-down default security group

S3 Public Access Block

S3 versioning

S3 SSE-KMS encryption

KMS automatic rotation

CloudTrail logging and configuration

CloudTrail -> S3 delivery

S3 HTTPS-only bucket policy

CloudTrail log-file integrity validation

SNS encryption and CloudTrail publishing policy

IAM role existence, policies, and trust relationships

CloudTrail log validation result for the verified window:

1/1 digest files valid
13/13 log files valid

A cloudtrail:LookupEvents query was also successfully authorized; a sample GetRole query returned no matching event rather than an authorization error.

Testing

The test suite is located at:

tests/test_security.py

It checks security properties of the Terraform configuration, including:

Terraform formatting

Terraform validation

SSH/RDP exposure restrictions

Security-group port restrictions

S3 public-access protection

S3 encryption

S3 versioning

IAM wildcard permissions

Administrator access restrictions

HTTPS enforcement

KMS key rotation

CloudTrail configuration

Multi-region logging

Log-file validation

The latest verified result is:

20 passed

These tests validate the Terraform configuration and do not require AWS credentials.

Repository Structure

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

Technologies

Technology

Purpose

AWS

Cloud infrastructure and security services

Terraform 1.15.8

Infrastructure as Code

AWS VPC

Network isolation and segmentation

AWS IAM

Identity and access management

AWS KMS

Encryption key management

Amazon S3

Secure audit-log storage

AWS CloudTrail

API activity auditing

Amazon SNS

Notifications and alerting

GitHub Actions

CI/CD automation

Checkov 3.3.18

Terraform security scanning

Python 3.12

Security test automation

pytest

Automated testing

detect-secrets 1.5.0

Secret scanning

Deployment / Usage

Prerequisites

Terraform 1.15.8

AWS CLI v2

An AWS IAM Identity Center profile with appropriate permissions

Python environment for security tests

Initialize

terraform -chdir=terraform init

Validate

terraform -chdir=terraform validate

Plan

terraform -chdir=terraform plan -var="aws_region=eu-central-1" -out=tfplan

Review the plan carefully before applying it.

Apply

terraform -chdir=terraform apply tfplan

Destroy

terraform -chdir=terraform destroy -var="aws_region=eu-central-1"

Only run destroy when you intentionally want to remove the managed AWS resources.

Security Notes

AWS Credentials

Never commit:

AWS access keys

Secret keys

API tokens

Passwords

.env files

Sensitive .tfvars files

Prefer IAM Identity Center for local development and short-lived credentials over long-lived access keys.

Terraform State

Terraform state may contain sensitive infrastructure information.

Do not commit:

terraform.tfstate
terraform.tfstate.backup

The repository .gitignore excludes Terraform state and generated files. For collaborative environments, configure a remote state backend with appropriate locking.

Before Applying Changes

Always inspect:

terraform -chdir=terraform plan -var="aws_region=eu-central-1"

before applying infrastructure changes.

Future / Deferred Components

The current baseline intentionally leaves several workload and operational components outside the deployed security foundation:

NAT Gateway for controlled private-subnet internet egress

EC2 workload instances

Database layer such as Amazon RDS

VPC Flow Logs

Additional CloudWatch/SIEM integration

S3 lifecycle and cross-region replication enhancements

Remote Terraform state and locking

GitHub Actions AWS OIDC deployment workflow

An SNS subscriber such as email, SQS, or Lambda for end-user alert delivery

These can be introduced based on workload, operational, security, and cost requirements.

Project Status

The core AWS security foundation is deployed and has been verified directly in AWS.

Current verified status:

Terraform formatting and validation pass

Checkov: 92 passed / 0 failed / 11 skipped

Security tests: 20 passed

Secret scanning passes

GitHub Actions pipeline passes with zero warnings

VPC, subnet, routing, security groups, IAM, KMS, S3, CloudTrail, and SNS controls verified in AWS

CloudTrail log integrity verification: 13/13 log files valid

Core workload components such as EC2, NAT Gateway, and RDS remain deferred

The repository demonstrates a Cloud Security / DevSecOps workflow combining Infrastructure as Code, security hardening, audit logging, automated security testing, and direct AWS verification.

Additional Documentation

Security Baseline

Security Testing

Threat Model

Incident Response

AWS Cost Safety

License

See the repository LICENSE file for licensing information.