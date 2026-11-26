# Reliable On-Demand Infrastructure and Health Monitoring for a Student Result Portal

A practical DevOps project using **Terraform**, **Puppet**, and **Nagios** to solve the classic university exam-day crash problem.

## Real-Life Problem
College exam result portals often fail during peak traffic because:
- Servers are provisioned manually with inconsistent settings.
- Access logs fill up the disk or memory spikes go unnoticed until students complain.
- Idle VMs sit running after exam season, wasting cloud budget.

## How the 3 Tools Work Together

| Tool | Responsibility | What It Does in This Project |
|---|---|---|
| **Terraform** | Infrastructure Provisioning | Creates the **Portal VM**, **Nagios Monitor VM**, and strict **Security Groups** (`80`, `443`, `22`, NRPE `5666`, internal DB `3306`). Includes `exam_season_active` toggle to spin down the portal VM after results are published. |
| **Puppet** | Configuration Management | Standardizes **Nginx**, generates **SSL certificates**, configures **UFW firewall**, enforces **logrotate** (so logs never fill disk), installs **NRPE**, and runs every 5 minutes to self-heal stopped services. |
| **Nagios** | Health Monitoring & Alerting | Monitors **HTTP (`/health.html`)**, **HTTPS SSL**, **RAM usage**, **CPU load**, **Root Disk space**, and **Nginx process status** on a live dashboard. |

## Architecture

```text
Students (Browser)
       │  HTTP (80) / HTTPS (443)
       ▼
┌─────────────────────────────────────────┐       NRPE (5666)        ┌──────────────────────────────┐
│  Portal Server (EC2 - portal_server)    │ ◄─────────────────────── │ Nagios Server (nagios_server)│
│  • Nginx + Student Result Portal UI     │                          │ • Nagios 4 Web Dashboard     │
│  • Self-signed SSL + UFW Firewall       │                          │ • HTTP / SSL / Load / RAM    │
│  • Logrotate (7-day compressed logs)    │                          │ • Disk / Process Alerts      │
│  • Puppet Self-Heal Cron (every 5 min)  │                          └──────────────────────────────┘
└─────────────────────────────────────────┘                                         ▲
                                                                                    │
                                                                      Admin Browser (:80/nagios4)
```

## Project Structure

```text
university-result-portal-devops/
├── portal-app/
│   ├── index.html                  # Student Result Portal UI (sample roll nos: CS202601, CS202602, EC202610)
│   └── health.html                 # Lightweight health endpoint for Nagios check_http
├── terraform/
│   ├── main.tf                     # Security groups + EC2 instances + Puppet user_data bootstrap
│   ├── variables.tf                # Region, instance type, SSH key, exam_season_active toggle
│   ├── outputs.tf                  # Portal URL and Nagios Dashboard URL
│   ├── terraform.tfvars.example    # Example variables file
│   └── cloud-init/
│       ├── bootstrap_portal.sh.tftpl
│       └── bootstrap_nagios.sh.tftpl
├── puppet/
│   ├── manifests/
│   │   └── site.pp                 # Role dispatcher (portal vs nagios)
│   └── modules/
│       ├── portal_web/             # Nginx, SSL, UFW, logrotate, NRPE, check_ram.sh
│       └── nagios_server/          # Nagios 4, Apache2, host & service checks
└── nagios/
    └── portal_host.cfg             # Reference Nagios host & service check definitions
```

## Quick Start (AWS Free Tier)

### 1. Prerequisites
- [Terraform](https://developer.hashicorp.com/terraform/install) (`>= 1.5.0`)
- An AWS account with configured credentials (`aws configure`)
- An existing EC2 Key Pair in your chosen region

### 2. Configure Variables
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```
Edit `terraform.tfvars` and set your `key_name`, `aws_region`, and `nagios_admin_password`.

### 3. Provision & Configure
```bash
terraform init
terraform plan
terraform apply
```
Wait ~3–5 minutes after `terraform apply` finishes for `cloud-init` and `puppet apply` to install Nginx, Puppet modules, and Nagios 4.

### 4. Access the Portals
- **Student Result Portal:** `http://<portal_public_ip>` (test with Roll No `CS202601`)
- **Nagios Dashboard:** `http://<nagios_public_ip>/nagios4`
  - Username: `nagiosadmin`
  - Password: value of `nagios_admin_password`

---

## Live Demos (Great for Viva / Interviews)

### Demo 1: On-Demand Cost Saving (After Exam Season)
1. Open `terraform/terraform.tfvars` and change:
   ```hcl
   exam_season_active = false
   ```
2. Run `terraform apply`.
3. Terraform destroys only the `portal_server` VM and `portal_sg` security rules (and Puppet removes the host check from Nagios), saving compute costs until the next semester.

### Demo 2: Alerting & Self-Healing Drift Remediation
1. Open the Nagios dashboard (`Services`) — all 6 portal checks are **OK (Green)**.
2. SSH into the Portal VM and simulate a crash:
   ```bash
   sudo systemctl stop nginx
   ```
3. Within ~1 minute, Nagios flags **Portal HTTP Availability** and **Nginx Web Process** as **CRITICAL (Red)**.
4. Wait up to 5 minutes (or run `sudo puppet apply ...`) — Puppet detects the drift, restarts Nginx automatically, and Nagios returns to **OK (Green)**.

## Cleanup
To destroy all created AWS resources:
```bash
cd terraform
terraform destroy
```
