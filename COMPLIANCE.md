# Compliance Mapping & Control Traceability

This document maps the technical resources in the **Cloud Platform Control Plane** to specific regulatory controls (ISO 27001, TISAX, and GDPR).

## 📊 Control Mapping Table

| Framework Control | Description | Technical Implementation (Terraform) |
| :--- | :--- | :--- |
| **ISO 27001: A.9.2.1** | User Registration & De-registration | Managed via `modules/core/iam/roles.tf` (IAM Roles only, no permanent users). |
| **ISO 27001: A.12.4.1** | Event Logging | Global visibility enforced in `modules/core/logging/cloudtrail.tf`. |
| **ISO 27001: A.12.4.2** | Protection of Log Information | Encrypted S3 buckets and public access blocks in `modules/core/logging/trail_bucket.tf`. |
| **TISAX: 5.2.2** | Resource Management | Automated enforcement via `modules/quotas/main.tf`. |
| **TISAX: 8.1.1** | Privilege Management | Condition-based emergency access in `modules/break_glass/main.tf`. |
| **GDPR: Article 32** | Security of Processing | Account-wide encryption and anomaly detection in `modules/cost_controls/` and `modules/core/`. |

## 🛡️ Evidence Generation
Every deployment of this control plane generates a **Terraform Plan**. This plan serves as "Point-in-Time" evidence for auditors, proving that these specific security configurations were active and enforced.

## 🚨 Incident Response Alignment
The **SIEM Integration** module (`modules/siem/`) ensures that technical telemetry is off-boarded to a central monitoring system, fulfilling the requirement for centralized log management and forensic readiness.