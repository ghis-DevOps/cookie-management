# cookie-management



Below is a complete, professional `README.md` you can place at the root of your Terraform project. It is written to be useful both for **actual implementation** and as a **Senior DevOps portfolio/interview project**.

# Cookie Management Platform — AWS Automation with Terraform

## Overview

This project provides a reusable **Infrastructure as Code (IaC)** implementation for administering and automating a Cookie Management platform using Terraform and AWS.

The solution is designed to support the following operational requirements:

* Onboard new web applications.
* Maintain application-specific cookie-management configuration.
* Categorize applications and cookies.
* Apply branding configuration.
* Perform recurring website scans.
* Publish updated cookie-management scripts on a recurring schedule.
* Secure Cookie Management API credentials.
* Automate scheduled operations using Amazon EventBridge.
* Execute automation through AWS Lambda.
* Apply least-privilege IAM permissions.
* Centralize operational logs in Amazon CloudWatch.
* Manage the entire infrastructure lifecycle using Terraform.

The architecture is intentionally **flat and modular by Terraform file**, without Terraform modules, making it easy to understand, maintain, extend, and use as a reference implementation.

---

# Architecture

```text
                         Git / Terraform
                               |
                               v
                    +----------------------+
                    |    AWS Resources     |
                    |     Terraform        |
                    +----------+-----------+
                               |
             +-----------------+------------------+
             |                                    |
             v                                    v
   EventBridge Scan Schedule          EventBridge Publish Schedule
             |                                    |
             v                                    v
      Scan Lambda                         Publish Lambda
             |                                    |
             +----------------+-------------------+
                              |
                              v
                  Cookie Management Platform
                              |
             +----------------+----------------+
             |                |                |
             v                v                v
        Applications       Cookies         Branding
             |
             v
       Website Scanning
             |
             v
       Updated Cookie Scripts
```

---

# AWS Services Used

| AWS Service                | Purpose                                             |
| -------------------------- | --------------------------------------------------- |
| **AWS Lambda**             | Executes website scanning and publishing automation |
| **Amazon EventBridge**     | Provides recurring scan and publishing schedules    |
| **AWS IAM**                | Controls access using least-privilege permissions   |
| **AWS Secrets Manager**    | Securely stores Cookie Management API credentials   |
| **Amazon CloudWatch Logs** | Stores Lambda execution logs                        |
| **Amazon ECR**             | Not required by the current implementation          |
| **Amazon ECS**             | Not required by the current implementation          |
| **Terraform**              | Provisions and manages the infrastructure           |

---

# Project Structure

```text
cookie-management/
│
├── provider.tf
├── variables.tf
├── terraform.tfvars
├── main.tf
├── iam.tf
├── lambda.tf
├── eventbridge.tf
├── cloudwatch.tf
├── secrets.tf
├── outputs.tf
│
└── lambda/
    ├── scan.py
    └── publish.py
```

---

# File Responsibilities

## `provider.tf`

Defines:

* Terraform version requirements.
* AWS provider.
* AWS region.
* Default resource tags.

Example:

```hcl
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = var.owner
    }
  }
}
```

---

# `variables.tf`

Defines reusable configuration variables.

Important variables include:

```hcl
variable "aws_region" {
  type    = string
  default = "us-east-1"
}
```

```hcl
variable "project_name" {
  type    = string
  default = "cookie-management"
}
```

```hcl
variable "environment" {
  type    = string
  default = "dev"
}
```

```hcl
variable "cookie_api_url" {
  type = string
}
```

```hcl
variable "scan_schedule" {
  type    = string
  default = "rate(7 days)"
}
```

```hcl
variable "publish_schedule" {
  type    = string
  default = "rate(7 days)"
}
```

Applications are represented as a Terraform map:

```hcl
variable "applications" {
  type = map(object({
    website_url = string
    category    = string
    brand       = string
    enabled     = optional(bool, true)
  }))
}
```

This makes onboarding additional applications configuration-driven.

---

# Application Configuration

Applications can be defined in `terraform.tfvars`.

Example:

```hcl
applications = {

  website_a = {
    website_url = "https://www.example.com"
    category    = "corporate"
    brand       = "primary"
    enabled     = true
  }

  website_b = {
    website_url = "https://shop.example.com"
    category    = "ecommerce"
    brand       = "commerce"
    enabled     = true
  }

}
```

To onboard another application:

```hcl
website_c = {
  website_url = "https://portal.example.com"
  category    = "customer-portal"
  brand       = "corporate"
  enabled     = true
}
```

Terraform then makes the configuration available to the Lambda automation.

---

# `secrets.tf`

The Cookie Management API credentials are stored in **AWS Secrets Manager**.

Example:

```hcl
resource "aws_secretsmanager_secret" "cookie_api" {
  name = var.cookie_api_secret_name

  description = "Cookie Management platform API credentials"

  recovery_window_in_days = 7
}
```

The API key should **never be hard-coded** into:

* Terraform code.
* Python code.
* GitHub Actions YAML.
* `terraform.tfvars`.
* Dockerfiles.
* Git repositories.

Populate the secret separately:

```bash
aws secretsmanager put-secret-value \
  --secret-id cookie-management/api \
  --secret-string '{"api_key":"YOUR_API_KEY"}'
```

---

# IAM Security

The Lambda functions use a dedicated IAM role.

The role allows Lambda to execute and write logs:

```hcl
resource "aws_iam_role" "cookie_lambda" {
  name = "${var.project_name}-${var.environment}-lambda-role"

  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}
```

The role also receives access to the specific Secrets Manager secret.

```hcl
actions = [
  "secretsmanager:GetSecretValue"
]
```

The design follows the **principle of least privilege**.

Lambda does not receive unrestricted access to AWS resources.

---

# Lambda Automation

Two Lambda functions are used.

## Scan Lambda

```text
lambda/scan.py
```

Responsible for:

1. Retrieving the API credential.
2. Loading application configuration.
3. Iterating through enabled applications.
4. Sending application information to the Cookie Management API.
5. Starting website scans.
6. Recording results.
7. Returning execution status.

The Lambda receives:

```text
COOKIE_API_URL
SECRET_ARN
APPLICATIONS_JSON
```

as environment variables.

---

# Publish Lambda

```text
lambda/publish.py
```

Responsible for:

1. Retrieving the Cookie Management API credential.
2. Loading application configuration.
3. Identifying enabled applications.
4. Calling the Cookie Management API.
5. Publishing updated cookie-management configuration/scripts.
6. Returning publishing results.

---

# EventBridge Automation

The recurring automation is defined in:

```text
eventbridge.tf
```

There are two schedules.

## Website Scan

```hcl
resource "aws_cloudwatch_event_rule" "cookie_scan" {
  name = "${var.project_name}-${var.environment}-scan"

  description = "Recurring Cookie Management website scan"

  schedule_expression = var.scan_schedule
}
```

The EventBridge rule invokes:

```hcl
aws_lambda_function.scan
```

---

# Recurring Publishing

The publishing schedule is:

```hcl
resource "aws_cloudwatch_event_rule" "cookie_publish" {
  name = "${var.project_name}-${var.environment}-publish"

  description = "Recurring Cookie Management script publishing"

  schedule_expression = var.publish_schedule
}
```

The publishing rule invokes:

```hcl
aws_lambda_function.publish
```

EventBridge is explicitly granted permission to invoke the Lambda:

```hcl
resource "aws_lambda_permission" "allow_publish_eventbridge" {
  statement_id = "AllowEventBridgePublish"

  action = "lambda:InvokeFunction"

  function_name = aws_lambda_function.publish.function_name

  principal = "events.amazonaws.com"

  source_arn = aws_cloudwatch_event_rule.cookie_publish.arn
}
```

---

# Automation Flow

The complete operational flow is:

```text
                    Application Configuration
                              |
                              v
                         Terraform
                              |
                 +------------+------------+
                 |                         |
                 v                         v
          Scan Schedule             Publish Schedule
                 |                         |
                 v                         v
          EventBridge                EventBridge
                 |                         |
                 v                         v
           Scan Lambda               Publish Lambda
                 |                         |
                 +------------+------------+
                              |
                              v
                   Cookie Management API
                              |
                +-------------+-------------+
                |                           |
                v                           v
          Website Scanning          Script Publishing
```

---

# Scheduling

The default configuration runs operations every seven days:

```hcl
scan_schedule = "rate(7 days)"

publish_schedule = "rate(7 days)"
```

You can change the schedule.

For example:

```hcl
scan_schedule = "rate(1 day)"
```

or use a cron expression:

```hcl
scan_schedule = "cron(0 2 ? * SUN *)"
```

The appropriate schedule depends on the organization's compliance requirements and operational policy.

---

# CloudWatch Logging

Lambda execution logs are stored in CloudWatch.

Example:

```hcl
resource "aws_cloudwatch_log_group" "scan" {
  name = "/aws/lambda/${aws_lambda_function.scan.function_name}"

  retention_in_days = 30
}
```

A separate log group is created for the publishing Lambda.

Logs can be used for:

* Troubleshooting.
* Audit investigation.
* Scan failures.
* API failures.
* Publishing failures.
* Operational monitoring.

---

# Deployment

## Prerequisites

Install:

* Terraform >= 1.6
* AWS CLI
* Python 3.x
* An AWS account
* AWS credentials with permission to create the required resources.
* Access to the Cookie Management platform API.

Verify Terraform:

```bash
terraform version
```

Verify AWS:

```bash
aws sts get-caller-identity
```

---

# Configure AWS Authentication

For local development:

```bash
aws configure
```

Verify:

```bash
aws sts get-caller-identity
```

For CI/CD, use short-lived authentication such as **GitHub Actions OIDC** rather than storing long-lived AWS access keys.

---

# Configure Variables

Create:

```text
terraform.tfvars
```

Example:

```hcl
aws_region   = "us-east-1"
project_name = "cookie-management"
environment  = "dev"
owner        = "platform-engineering"

cookie_api_url = "https://api.example-cookie-platform.com"

cookie_api_secret_name = "cookie-management/api"

scan_schedule = "rate(7 days)"

publish_schedule = "rate(7 days)"

applications = {

  website_a = {
    website_url = "https://www.example.com"
    category    = "corporate"
    brand       = "primary"
    enabled     = true
  }

  website_b = {
    website_url = "https://shop.example.com"
    category    = "ecommerce"
    brand       = "commerce"
    enabled     = true
  }

}
```

Do not commit sensitive credentials.

Add:

```text
terraform.tfvars
*.tfstate
*.tfstate.*
.terraform/
```

to `.gitignore` as appropriate.

---

# Initialize Terraform

Run:

```bash
terraform init
```

This downloads the required AWS provider.

---

# Format Terraform

Run:

```bash
terraform fmt -recursive
```

---

# Validate Configuration

Run:

```bash
terraform validate
```

Expected result:

```text
Success! The configuration is valid.
```

---

# Review the Deployment

Run:

```bash
terraform plan
```

Review the resources Terraform intends to create.

---

# Deploy Infrastructure

Run:

```bash
terraform apply
```

Confirm with:

```text
yes
```

Terraform will create:

* IAM role.
* IAM policies.
* Secrets Manager secret.
* Scan Lambda.
* Publish Lambda.
* EventBridge scan rule.
* EventBridge publishing rule.
* Lambda permissions.
* CloudWatch log groups.

---

# Verify EventBridge

List EventBridge rules:

```bash
aws events list-rules
```

You should see resources similar to:

```text
cookie-management-dev-scan
cookie-management-dev-publish
```

---

# Verify Lambda Functions

```bash
aws lambda list-functions
```

Look for:

```text
cookie-management-dev-scan
cookie-management-dev-publish
```

---

# Test the Scan Lambda

You can manually invoke the scan function:

```bash
aws lambda invoke \
  --function-name cookie-management-dev-scan \
  response.json
```

View the response:

```bash
cat response.json
```

---

# Test the Publish Lambda

```bash
aws lambda invoke \
  --function-name cookie-management-dev-publish \
  response.json
```

Then:

```bash
cat response.json
```

---

# View Lambda Logs

List log groups:

```bash
aws logs describe-log-groups
```

Tail scan logs:

```bash
aws logs tail \
  /aws/lambda/cookie-management-dev-scan \
  --follow
```

Tail publishing logs:

```bash
aws logs tail \
  /aws/lambda/cookie-management-dev-publish \
  --follow
```

---

# Destroy the Environment

For a development environment:

```bash
terraform destroy
```

Review the resources before confirming.

```text
yes
```

**Do not run `terraform destroy` against production without following the organization's change-management and approval process.**

---

# Security Considerations

## Secrets

Never commit:

```text
API keys
AWS access keys
passwords
tokens
private certificates
```

Use:

```text
AWS Secrets Manager
```

or another approved secrets-management platform.

---

## IAM

The Lambda role should follow least privilege.

Instead of:

```text
secretsmanager:*
```

use:

```text
secretsmanager:GetSecretValue
```

and restrict the resource to the specific secret.

---

## Terraform State

Terraform state can contain sensitive infrastructure information.

For production, use a remote backend such as:

```text
Amazon S3
```

with:

```text
S3 encryption
Versioning
Restricted IAM access
State locking / concurrency protection
```

A typical enterprise architecture is:

```text
GitHub
   |
   v
Terraform
   |
   v
S3 Remote State
   |
   v
AWS Infrastructure
```

---

# CI/CD Integration

This Terraform project can be integrated into GitHub Actions.

Recommended workflow:

```text
Developer
    |
    v
GitHub Pull Request
    |
    v
Terraform fmt
    |
    v
Terraform validate
    |
    v
Terraform plan
    |
    v
Security / Compliance Checks
    |
    v
Code Review
    |
    v
Terraform Apply
    |
    v
AWS
```

GitHub Actions should authenticate to AWS using:

```text
GitHub OIDC
        |
        v
AWS IAM Role
        |
        v
Temporary AWS Credentials
```

Avoid long-lived AWS access keys in GitHub secrets.

---

# Compliance Automation

This architecture can be extended to enforce organizational compliance requirements.

Potential controls include:

* Required resource tagging.
* IAM least privilege.
* Encryption requirements.
* CloudWatch logging.
* Secrets Manager usage.
* TLS/HTTPS enforcement.
* Restricted network access.
* Terraform policy validation.
* Repository security checks.
* Vulnerability scanning.
* Change approval.
* Infrastructure drift detection.

A potential pipeline is:

```text
Git Push
   |
   v
Terraform Format
   |
   v
Terraform Validate
   |
   v
Security Scan
   |
   v
Compliance Check
   |
   v
Terraform Plan
   |
   v
Approval
   |
   v
Terraform Apply
```

---

# Production Enhancements

The current implementation is intentionally simple and flat. For production, the following improvements can be added.

## 1. Remote Terraform State

Use S3 for centralized state management.

```text
S3
 └── terraform/
      └── cookie-management/
           ├── dev/
           ├── staging/
           └── prod/
```

---

## 2. Multiple Environments

Separate:

```text
dev
staging
prod
```

Each environment should have independent configuration and appropriate access controls.

---

## 3. Lambda VPC Integration

If the Cookie Management API is private, place Lambda inside the appropriate VPC and configure:

* Private subnets.
* Security groups.
* NAT Gateway or private connectivity.
* VPC endpoints where appropriate.

---

## 4. Monitoring and Alerting

Add:

* CloudWatch alarms.
* SNS notifications.
* Lambda error alarms.
* EventBridge failure monitoring.
* API failure monitoring.

Example:

```text
Lambda Failure
      |
      v
CloudWatch Alarm
      |
      v
SNS
      |
      v
Engineering Notification
```

---

## 5. Dead-Letter Queue

For production EventBridge/Lambda automation, consider adding an SQS dead-letter queue for failed asynchronous invocations.

```text
EventBridge
     |
     v
Lambda
     |
   Failure
     |
     v
SQS DLQ
```

This helps prevent failed automation events from being silently lost.

---

## 6. API Retry and Backoff

The Lambda API integration should implement:

* Connection timeouts.
* HTTP status validation.
* Exponential backoff.
* Retry handling.
* Rate-limit handling.
* Structured error logging.

This becomes particularly important when onboarding a large number of applications.

---

# Important API Integration Note

The Python code in this project uses generic endpoints such as:

```text
/scans
/publish
```

These are **placeholders**.

The actual endpoints, request payloads, authentication mechanism, and response format must be adapted to the specific Cookie Management platform being used by the organization.

The Terraform architecture does not depend on a particular vendor.

---

# Operational Responsibilities

This implementation supports the following operational responsibilities:

### Application onboarding

Add application configuration:

```hcl
website_url = "https://example.com"
```

### Cookie categorization

Define the appropriate application/category configuration.

### Branding

Associate the appropriate brand configuration.

### Website scanning

EventBridge automatically triggers the scan Lambda.

### Script publishing

EventBridge automatically triggers the publishing Lambda.

### Credential management

Secrets Manager stores API credentials.

### Access control

IAM controls AWS permissions.

### Observability

CloudWatch provides execution logs.

### Infrastructure lifecycle

Terraform manages the infrastructure.

---

# Design Principles

The project follows several DevOps/IaC principles:

### Infrastructure as Code

Infrastructure is defined declaratively using Terraform.

### Automation

Recurring operational tasks are automated rather than manually executed.

### Least Privilege

AWS resources receive only the permissions they require.

### Secrets Management

Credentials are stored outside source code.

### Configuration Driven

New applications can be onboarded through configuration.

### Repeatability

The infrastructure can be recreated consistently.

### Observability

Lambda operations are logged to CloudWatch.

### CI/CD Ready

The Terraform configuration can be integrated into a GitHub Actions pipeline.

---

# Troubleshooting

## Terraform cannot find a resource

Run:

```bash
terraform validate
```

For example, if you see:

```text
Reference to undeclared resource
```

verify that the referenced resource exists in another `.tf` file in the same directory.

Terraform automatically loads all `.tf` files in the directory.

---

## Lambda cannot retrieve the secret

Check the Lambda IAM role:

```bash
aws iam get-role \
  --role-name cookie-management-dev-lambda-role
```

Verify that the role has:

```text
secretsmanager:GetSecretValue
```

against the correct secret ARN.

---

## EventBridge does not trigger Lambda

Check:

```bash
aws events list-rules
```

Then verify Lambda permissions:

```bash
aws lambda get-policy \
  --function-name cookie-management-dev-scan
```

You should see:

```text
events.amazonaws.com
```

as an allowed principal.

---

## Lambda execution fails

Check:

```bash
aws logs tail \
  /aws/lambda/cookie-management-dev-scan \
  --follow
```

and:

```bash
aws logs tail \
  /aws/lambda/cookie-management-dev-publish \
  --follow
```

---

# Future Architecture

The project can eventually evolve into:

```text
                         GitHub
                            |
                            v
                    GitHub Actions
                            |
              +-------------+-------------+
              |                           |
              v                           v
       Terraform Plan              Security Scan
              |                           |
              +-------------+-------------+
                            |
                            v
                       Approval
                            |
                            v
                    Terraform Apply
                            |
                            v
                         AWS
                            |
        +-------------------+-------------------+
        |                   |                   |
        v                   v                   v
   EventBridge          Secrets Manager      CloudWatch
        |                                       |
   +----+----+                                  |
   |         |                                  |
   v         v                                  |
 Scan      Publish                              |
 Lambda     Lambda                              |
   |         |                                  |
   +----+----+                                  |
        |                                       |
        v                                       |
 Cookie Management API <------------------------+
```

---

# Summary

This Terraform project provides an automated AWS-based foundation for managing a Cookie Management platform.

The solution uses:

```text
Terraform
   +
AWS Lambda
   +
Amazon EventBridge
   +
AWS IAM
   +
AWS Secrets Manager
   +
Amazon CloudWatch
```

to automate:

```text
Application Onboarding
        ↓
Cookie Configuration
        ↓
Branding
        ↓
Recurring Website Scans
        ↓
Cookie Script Publishing
        ↓
Monitoring and Logging
```

The design is intentionally simple enough for development and learning while providing a foundation that can be extended for enterprise requirements such as remote Terraform state, CI/CD, compliance enforcement, centralized logging, monitoring, alerting, multi-environment deployments, and private API connectivity.
