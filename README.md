# Cloud Platform Control Plane

**Cloud Platform Control Plane** is a modular, feature-flag-driven security factory for AWS. It transforms a raw AWS account into a managed, audit-ready enterprise environment.

Unlike static landing zones, this project operates as a **configurable control plane**. It establishes a non-negotiable security baseline (Core) and allows for the selective deployment of advanced governance modules (SIEM, Cost Controls, Emergency Access) via simple feature flags.

---

## 🛡️ Capabilities & Architecture

This project is structured into **Core** (Always On) and **Optional** (Feature Flagged) layers.

### 🚀 Core Layer (Mandatory)
* **Identity Foundation:** Zero-trust IAM setup with dedicated Admin, Security, and Automation roles.
* **Blast Radius Control:** Permission boundaries applied to all automation roles to prevent privilege escalation.
* **Immutable Logging:** Multi-region CloudTrail with encrypted, tamper-proof S3 storage.
* **Data Perimeter:** Account-wide S3 Public Access Block.
* **Security Alerting:** Centralized SNS topic for critical security notifications.

### 🧩 Optional Modules (Toggle via Flags)
| Module | Purpose | GRC/Audit Relevance |
| :--- | :--- | :--- |
| **Quota Guardrails** | Enforces service limits (e.g., VPC count) to prevent resource abuse. | Service Level Management, Anti-Abuse |
| **Break Glass** | Deploys a highly privileged "Emergency Role" protected by mandatory MFA. | Emergency Operations, Separation of Duties |
| **Cost Controls** | Sets AWS Budgets and AI-powered Cost Anomaly Detection. | Financial Governance, FinOps |
| **SIEM Integration** | Kinesis Data Firehose pipeline to ship logs to external aggregators (Splunk/Datadog). | Centralized Logging & Monitoring (TISAX/ISO) |

---

## 📂 Project Structure

```text
.
├── LICENSE
├── README.md
├── enterprise_strict.tfvars      # Preset for "Max Security" mode
├── main.tf                       # Root controller (Feature Flag logic)
├── variables.tf                  # Global variables & Feature Map definition
├── outputs.tf                    # High-level outputs (SNS topics, ARNs)
├── provider.tf                   # AWS Provider configuration
└── modules/
    ├── core/                     # The immutable security baseline
    │   ├── alerts/
    │   ├── iam/
    │   ├── logging/
    │   ├── s3/
    │   └── docs/                 # Remediation runbooks
    ├── break_glass/              # Emergency access module
    ├── cost_controls/            # Budget & Anomaly detection
    ├── quotas/                   # Service limit enforcement
    └── siem/                     # Log forwarding infrastructure

```

---

## ⚙️ Configuration & Feature Flags

The control plane is managed via a single `features` map variable. You can toggle modules on/off without changing the underlying code.

**Example Configuration (`terraform.tfvars`):**

```hcl
aws_region           = "ap-south-1"
security_alert_email = "secops@example.com"

# The Control Plane Switchboard
features = {
  siem_integration = true   # Ship logs to SIEM?
  quotas           = true   # Enforce resource limits?
  break_glass      = true   # Deploy emergency access?
  cost_controls    = true   # Enable budget alerts?
}

```

---

## 🚀 Deployment Guide

### Prerequisites

1. **Fresh AWS Account** (Recommended).
2. **Root User Remediation:**
* Enable MFA on Root.
* Delete Root Access Keys.
* *See `modules/core/docs/remediation.md` for the manual checklist.*



### Step 1: Initialize

Clone the repository and initialize Terraform.

```bash
terraform init

```

### Step 2: Plan (Choose Your Mode)

You can deploy with different presets.

**Option A: Startup Mode (Core Only)**

```bash
terraform plan

```

**Option B: Enterprise Mode (All Features Enabled)**

```bash
terraform plan -var-file="enterprise_strict.tfvars"

```

### Step 3: Apply

```bash
terraform apply -var-file="enterprise_strict.tfvars"

```

---

## 🔒 Security Model (Defense-in-Depth)

| Layer | Control Mechanism |
| --- | --- |
| **Preventive** | IAM Roles, Permission Boundaries, S3 Public Blocks, Service Quotas |
| **Detective** | CloudTrail, Cost Anomaly Detection, SIEM Log Shipping |
| **Reactive** | SNS Alerts, Budget Notifications |
| **Recovery** | Break Glass Roles (Emergency Access) |

---

## 📜 License

This project is licensed under the Apache 2.0 License - see the [LICENSE](https://www.google.com/search?q=LICENSE) file for details.
