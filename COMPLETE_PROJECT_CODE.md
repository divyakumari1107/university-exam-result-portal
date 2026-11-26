# University Exam & Result Portal — Complete DevOps Project Code

**Topic:** Reliable On-Demand Infrastructure and Health Monitoring for a Student Result Portal  
**Tech Stack:** Terraform, Puppet, Nagios 4, Nginx, Ubuntu 22.04 LTS (AWS EC2)

---
## `README.md`

````markdown
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
       â”‚  HTTP (80) / HTTPS (443)
       â–¼
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”       NRPE (5666)        â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚  Portal Server (EC2 - portal_server)    â”‚ â—„â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ â”‚ Nagios Server (nagios_server)â”‚
â”‚  â€¢ Nginx + Student Result Portal UI     â”‚                          â”‚ â€¢ Nagios 4 Web Dashboard     â”‚
â”‚  â€¢ Self-signed SSL + UFW Firewall       â”‚                          â”‚ â€¢ HTTP / SSL / Load / RAM    â”‚
â”‚  â€¢ Logrotate (7-day compressed logs)    â”‚                          â”‚ â€¢ Disk / Process Alerts      â”‚
â”‚  â€¢ Puppet Self-Heal Cron (every 5 min)  â”‚                          â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜                                         â–²
                                                                                    â”‚
                                                                      Admin Browser (:80/nagios4)
```

## Project Structure

```text
university-result-portal-devops/
â”œâ”€â”€ portal-app/
â”‚   â”œâ”€â”€ index.html                  # Student Result Portal UI (sample roll nos: CS202601, CS202602, EC202610)
â”‚   â””â”€â”€ health.html                 # Lightweight health endpoint for Nagios check_http
â”œâ”€â”€ terraform/
â”‚   â”œâ”€â”€ main.tf                     # Security groups + EC2 instances + Puppet user_data bootstrap
â”‚   â”œâ”€â”€ variables.tf                # Region, instance type, SSH key, exam_season_active toggle
â”‚   â”œâ”€â”€ outputs.tf                  # Portal URL and Nagios Dashboard URL
â”‚   â”œâ”€â”€ terraform.tfvars.example    # Example variables file
â”‚   â””â”€â”€ cloud-init/
â”‚       â”œâ”€â”€ bootstrap_portal.sh.tftpl
â”‚       â””â”€â”€ bootstrap_nagios.sh.tftpl
â”œâ”€â”€ puppet/
â”‚   â”œâ”€â”€ manifests/
â”‚   â”‚   â””â”€â”€ site.pp                 # Role dispatcher (portal vs nagios)
â”‚   â””â”€â”€ modules/
â”‚       â”œâ”€â”€ portal_web/             # Nginx, SSL, UFW, logrotate, NRPE, check_ram.sh
â”‚       â””â”€â”€ nagios_server/          # Nagios 4, Apache2, host & service checks
â””â”€â”€ nagios/
    â””â”€â”€ portal_host.cfg             # Reference Nagios host & service check definitions
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
Wait ~3â€“5 minutes after `terraform apply` finishes for `cloud-init` and `puppet apply` to install Nginx, Puppet modules, and Nagios 4.

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
1. Open the Nagios dashboard (`Services`) â€” all 6 portal checks are **OK (Green)**.
2. SSH into the Portal VM and simulate a crash:
   ```bash
   sudo systemctl stop nginx
   ```
3. Within ~1 minute, Nagios flags **Portal HTTP Availability** and **Nginx Web Process** as **CRITICAL (Red)**.
4. Wait up to 5 minutes (or run `sudo puppet apply ...`) â€” Puppet detects the drift, restarts Nginx automatically, and Nagios returns to **OK (Green)**.

## Cleanup
To destroy all created AWS resources:
```bash
cd terraform
terraform destroy
```
````

## `terraform/variables.tf`

````hcl
variable "aws_region" {
  description = "AWS region where the exam portal infrastructure is deployed"
  type        = string
  default     = "ap-south-1"
}

variable "instance_type" {
  description = "EC2 instance size (t2.micro / t3.micro eligible for AWS Free Tier)"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Name of an existing AWS EC2 Key Pair for SSH access"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH into servers (restrict to your public IP/32 in production)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "exam_season_active" {
  description = "Toggle on-demand exam portal VM provisioning (set false after exam season to save costs)"
  type        = bool
  default     = true
}

variable "nagios_admin_password" {
  description = "Password for the Nagios Core web dashboard (username: nagiosadmin)"
  type        = string
  sensitive   = true
  default     = "ExamPortal@2026"
}
````

## `terraform/main.tf`

````hcl
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Use default VPC and subnets for a minimal, zero-setup starter deployment
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Latest Ubuntu 22.04 LTS AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# -----------------------------------------------------------------------------
# Security Groups (App, Database, and Monitoring Access Rules)
# -----------------------------------------------------------------------------

resource "aws_security_group" "nagios_sg" {
  name        = "result-portal-nagios-sg"
  description = "Security group for Nagios Core monitoring server"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Nagios Web Dashboard (HTTP)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Admin SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "result-portal-nagios-sg"
    Project = "UniversityResultPortal"
  }
}

resource "aws_security_group" "portal_sg" {
  count       = var.exam_season_active ? 1 : 0
  name        = "result-portal-app-sg"
  description = "Security group for Student Result Portal VM and internal DB access"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Student HTTP traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Student HTTPS traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description     = "Nagios NRPE monitoring checks from Nagios server only"
    from_port       = 5666
    to_port         = 5666
    protocol        = "tcp"
    security_groups = [aws_security_group.nagios_sg.id]
  }

  ingress {
    description = "Internal DB/App port restricted inside portal security group"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    self        = true
  }

  ingress {
    description = "Admin SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "result-portal-app-sg"
    Project = "UniversityResultPortal"
  }
}

# -----------------------------------------------------------------------------
# Compute Instances (On-Demand Exam Portal VM + Nagios Monitor VM)
# -----------------------------------------------------------------------------

resource "aws_instance" "nagios_server" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = data.aws_subnets.default.ids[0]
  vpc_security_group_ids      = [aws_security_group.nagios_sg.id]
  associate_public_ip_address = true

  user_data = templatefile("${path.module}/cloud-init/bootstrap_nagios.sh.tftpl", {
    nagios_admin_password = var.nagios_admin_password
    nagios_site_pp        = file("${path.module}/../puppet/manifests/site.pp")
    nagios_init_pp        = file("${path.module}/../puppet/modules/nagios_server/manifests/init.pp")
    nagios_host_cfg_erb   = file("${path.module}/../puppet/modules/nagios_server/templates/portal_host.cfg.erb")
    portal_private_ip     = var.exam_season_active ? aws_instance.portal_server[0].private_ip : "127.0.0.1"
    exam_season_active    = var.exam_season_active
  })

  tags = {
    Name    = "university-nagios-monitor"
    Role    = "monitoring"
    Project = "UniversityResultPortal"
  }
}

resource "aws_instance" "portal_server" {
  count                       = var.exam_season_active ? 1 : 0
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = data.aws_subnets.default.ids[0]
  vpc_security_group_ids      = [aws_security_group.portal_sg[0].id]
  associate_public_ip_address = true

  user_data = templatefile("${path.module}/cloud-init/bootstrap_portal.sh.tftpl", {
    portal_site_pp    = file("${path.module}/../puppet/manifests/site.pp")
    portal_init_pp    = file("${path.module}/../puppet/modules/portal_web/manifests/init.pp")
    portal_conf_erb   = file("${path.module}/../puppet/modules/portal_web/templates/portal.conf.erb")
    logrotate_erb     = file("${path.module}/../puppet/modules/portal_web/templates/logrotate_nginx.erb")
    nrpe_cfg_erb      = file("${path.module}/../puppet/modules/portal_web/templates/nrpe_portal.cfg.erb")
    portal_index_html = base64encode(file("${path.module}/../portal-app/index.html"))
    portal_health     = base64encode(file("${path.module}/../portal-app/health.html"))
  })

  tags = {
    Name    = "university-result-portal"
    Role    = "webserver"
    Project = "UniversityResultPortal"
  }
}
````

## `terraform/outputs.tf`

````hcl
output "exam_season_active" {
  description = "Whether the on-demand Student Result Portal VM is currently provisioned"
  value       = var.exam_season_active
}

output "portal_public_ip" {
  description = "Public IP of the Student Result Portal VM (null when exam_season_active is false)"
  value       = var.exam_season_active ? aws_instance.portal_server[0].public_ip : null
}

output "portal_url" {
  description = "HTTP URL for the Student Result Portal"
  value       = var.exam_season_active ? "http://${aws_instance.portal_server[0].public_ip}" : "Portal is scaled down (exam_season_active = false)"
}

output "nagios_public_ip" {
  description = "Public IP of the Nagios Monitoring Server"
  value       = aws_instance.nagios_server.public_ip
}

output "nagios_dashboard_url" {
  description = "URL for the Nagios Core web dashboard"
  value       = "http://${aws_instance.nagios_server.public_ip}/nagios4"
}
````

## `terraform/terraform.tfvars.example`

````hcl
aws_region            = "ap-south-1"
instance_type         = "t2.micro"
key_name              = "your-aws-keypair-name"
allowed_ssh_cidr      = "0.0.0.0/0"
exam_season_active    = true
nagios_admin_password = "ChangeMe@2026"
````

## `terraform/cloud-init/bootstrap_portal.sh.tftpl`

````bash
#!/bin/bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y puppet

mkdir -p /etc/puppet/code/environments/production/manifests
mkdir -p /etc/puppet/code/environments/production/modules/portal_web/manifests
mkdir -p /etc/puppet/code/environments/production/modules/portal_web/templates
mkdir -p /etc/puppet/code/environments/production/modules/portal_web/files

cat <<'EOF' > /etc/puppet/code/environments/production/manifests/site.pp
${portal_site_pp}
EOF

cat <<'EOF' > /etc/puppet/code/environments/production/modules/portal_web/manifests/init.pp
${portal_init_pp}
EOF

cat <<'EOF' > /etc/puppet/code/environments/production/modules/portal_web/templates/portal.conf.erb
${portal_conf_erb}
EOF

cat <<'EOF' > /etc/puppet/code/environments/production/modules/portal_web/templates/logrotate_nginx.erb
${logrotate_erb}
EOF

cat <<'EOF' > /etc/puppet/code/environments/production/modules/portal_web/templates/nrpe_portal.cfg.erb
${nrpe_cfg_erb}
EOF

echo "${portal_index_html}" | base64 -d > /etc/puppet/code/environments/production/modules/portal_web/files/index.html
echo "${portal_health}" | base64 -d > /etc/puppet/code/environments/production/modules/portal_web/files/health.html

# Set node role fact and apply Puppet configuration
mkdir -p /etc/facter/facts.d
cat <<'EOF' > /etc/facter/facts.d/portal_role.yaml
---
server_role: portal
nagios_allowed_subnet: "0.0.0.0/0"
EOF

puppet apply \
  --modulepath=/etc/puppet/code/environments/production/modules \
  /etc/puppet/code/environments/production/manifests/site.pp

# Schedule Puppet every 5 minutes for automatic drift remediation (self-healing)
cat <<'EOF' > /etc/cron.d/puppet-self-heal
*/5 * * * * root /usr/bin/puppet apply --modulepath=/etc/puppet/code/environments/production/modules /etc/puppet/code/environments/production/manifests/site.pp >/var/log/puppet-apply.log 2>&1
EOF
````

## `terraform/cloud-init/bootstrap_nagios.sh.tftpl`

````bash
#!/bin/bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y puppet

mkdir -p /etc/puppet/code/environments/production/manifests
mkdir -p /etc/puppet/code/environments/production/modules/nagios_server/manifests
mkdir -p /etc/puppet/code/environments/production/modules/nagios_server/templates

cat <<'EOF' > /etc/puppet/code/environments/production/manifests/site.pp
${nagios_site_pp}
EOF

cat <<'EOF' > /etc/puppet/code/environments/production/modules/nagios_server/manifests/init.pp
${nagios_init_pp}
EOF

cat <<'EOF' > /etc/puppet/code/environments/production/modules/nagios_server/templates/portal_host.cfg.erb
${nagios_host_cfg_erb}
EOF

mkdir -p /etc/facter/facts.d
cat <<EOF > /etc/facter/facts.d/portal_role.yaml
---
server_role: nagios
portal_server_ip: "${portal_private_ip}"
exam_season_active: ${exam_season_active}
nagios_admin_password: "${nagios_admin_password}"
EOF

puppet apply \
  --modulepath=/etc/puppet/code/environments/production/modules \
  /etc/puppet/code/environments/production/manifests/site.pp
````

## `puppet/manifests/site.pp`

````puppet
node default {
  $role = $facts['server_role']

  if $role == 'portal' {
    include portal_web
  } elsif $role == 'nagios' {
    include nagios_server
  } else {
    notify { 'Unknown server_role fact; skipping role configuration.': }
  }
}
````

## `puppet/modules/portal_web/manifests/init.pp`

````puppet
# Class: portal_web
# Configures the Student Result Portal server:
#   1. Nginx web server + self-signed SSL certificate
#   2. Logrotate rules to prevent disk exhaustion during exam traffic
#   3. UFW firewall rules (HTTP, HTTPS, SSH, and NRPE)
#   4. Nagios NRPE agent + RAM/CPU/Disk/Nginx checks
#   5. Service enforcement for self-healing on drift

class portal_web {
  $doc_root       = '/var/www/result-portal'
  $ssl_cert_path  = '/etc/ssl/certs/result-portal.crt'
  $ssl_key_path   = '/etc/ssl/private/result-portal.key'
  $allowed_hosts  = pick($facts['nagios_allowed_subnet'], '127.0.0.1')

  package { ['nginx', 'ufw', 'logrotate', 'openssl', 'nagios-nrpe-server', 'nagios-plugins']:
    ensure => installed,
  }

  # Generate self-signed SSL cert idempotently for HTTPS standardization
  exec { 'generate_portal_ssl':
    command => "/usr/bin/openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ${ssl_key_path} -out ${ssl_cert_path} -subj '/C=IN/ST=State/L=City/O=StateUniversity/CN=result-portal.local'",
    creates => $ssl_cert_path,
    require => Package['openssl'],
    notify  => Service['nginx'],
  }

  file { $doc_root:
    ensure => directory,
    owner  => 'www-data',
    group  => 'www-data',
    mode   => '0755',
  }

  file { "${doc_root}/index.html":
    ensure  => file,
    source  => 'puppet:///modules/portal_web/index.html',
    owner   => 'www-data',
    group   => 'www-data',
    mode    => '0644',
    require => File[$doc_root],
  }

  file { "${doc_root}/health.html":
    ensure  => file,
    source  => 'puppet:///modules/portal_web/health.html',
    owner   => 'www-data',
    group   => 'www-data',
    mode    => '0644',
    require => File[$doc_root],
  }

  # Disable default Nginx site and apply standardized portal vhost
  file { '/etc/nginx/sites-enabled/default':
    ensure  => absent,
    require => Package['nginx'],
    notify  => Service['nginx'],
  }

  file { '/etc/nginx/sites-available/result-portal.conf':
    ensure  => file,
    content => template('portal_web/portal.conf.erb'),
    mode    => '0644',
    require => Package['nginx'],
    notify  => Service['nginx'],
  }

  file { '/etc/nginx/sites-enabled/result-portal.conf':
    ensure  => link,
    target  => '/etc/nginx/sites-available/result-portal.conf',
    require => File['/etc/nginx/sites-available/result-portal.conf'],
    notify  => Service['nginx'],
  }

  # Standardize log rotation so exam-day access logs never fill up the disk
  file { '/etc/logrotate.d/result-portal-nginx':
    ensure  => file,
    content => template('portal_web/logrotate_nginx.erb'),
    mode    => '0644',
    require => Package['logrotate'],
  }

  # Custom lightweight RAM check script for Nagios NRPE
  file { '/usr/local/bin/check_ram.sh':
    ensure  => file,
    mode    => '0755',
    content => "#!/bin/bash\nUSED_PCT=\$(free | awk '/Mem:/ {printf \"%.0f\", \$3/\$2 * 100}')\nif [ \"\$USED_PCT\" -ge 90 ]; then\n  echo \"CRITICAL - Memory usage is \${USED_PCT}%\"\n  exit 2\nelif [ \"\$USED_PCT\" -ge 75 ]; then\n  echo \"WARNING - Memory usage is \${USED_PCT}%\"\n  exit 1\nelse\n  echo \"OK - Memory usage is \${USED_PCT}%\"\n  exit 0\nfi\n",
  }

  # Configure NRPE checks and allow monitoring host
  file { '/etc/nagios/nrpe.d/portal_checks.cfg':
    ensure  => file,
    content => template('portal_web/nrpe_portal.cfg.erb'),
    mode    => '0644',
    require => [Package['nagios-nrpe-server'], File['/usr/local/bin/check_ram.sh']],
    notify  => Service['nagios-nrpe-server'],
  }

  # Standardize UFW firewall rules
  exec { 'ufw_allow_rules':
    command => '/usr/sbin/ufw allow 22/tcp && /usr/sbin/ufw allow 80/tcp && /usr/sbin/ufw allow 443/tcp && /usr/sbin/ufw allow 5666/tcp && /usr/sbin/ufw --force enable',
    unless  => '/usr/sbin/ufw status | /bin/grep -q "Status: active"',
    require => Package['ufw'],
  }

  # Enforce running services (enables automatic recovery if Nginx stops)
  service { 'nginx':
    ensure  => running,
    enable  => true,
    require => [Package['nginx'], File['/etc/nginx/sites-enabled/result-portal.conf']],
  }

  service { 'nagios-nrpe-server':
    ensure  => running,
    enable  => true,
    require => Package['nagios-nrpe-server'],
  }
}
````

## `puppet/modules/portal_web/templates/portal.conf.erb`

````text
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name _;
    root <%= @doc_root %>;
    index index.html;

    access_log /var/log/nginx/result-portal.access.log;
    error_log  /var/log/nginx/result-portal.error.log;

    location / {
        try_files $uri $uri/ =404;
    }

    location = /health {
        try_files /health.html =404;
    }
}

server {
    listen 443 ssl default_server;
    listen [::]:443 ssl default_server;

    server_name _;
    root <%= @doc_root %>;
    index index.html;

    ssl_certificate     <%= @ssl_cert_path %>;
    ssl_certificate_key <%= @ssl_key_path %>;
    ssl_protocols       TLSv1.2 TLSv1.3;

    access_log /var/log/nginx/result-portal.access.log;
    error_log  /var/log/nginx/result-portal.error.log;

    location / {
        try_files $uri $uri/ =404;
    }

    location = /health {
        try_files /health.html =404;
    }
}
````

## `puppet/modules/portal_web/templates/logrotate_nginx.erb`

````text
/var/log/nginx/result-portal.*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 0640 www-data adm
    sharedscripts
    postrotate
        [ -s /run/nginx.pid ] && kill -USR1 $(cat /run/nginx.pid)
    endscript
}
````

## `puppet/modules/portal_web/templates/nrpe_portal.cfg.erb`

````text
# Managed by Puppet - NRPE checks for Student Result Portal
dont_blame_nrpe=0
allowed_hosts=127.0.0.1,::1,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16

command[check_portal_load]=/usr/lib/nagios/plugins/check_load -r -w 1.5,1.2,1.0 -c 3.0,2.5,2.0
command[check_portal_disk]=/usr/lib/nagios/plugins/check_disk -w 20% -c 10% -p /
command[check_portal_ram]=/usr/local/bin/check_ram.sh
command[check_portal_nginx]=/usr/lib/nagios/plugins/check_procs -c 1:20 -C nginx
````

## `puppet/modules/nagios_server/manifests/init.pp`

````puppet
# Class: nagios_server
# Installs and configures Nagios 4 + Apache2 to monitor the Student Result Portal.

class nagios_server {
  $portal_ip          = pick($facts['portal_server_ip'], '127.0.0.1')
  $exam_season_active = pick($facts['exam_season_active'], true)
  $admin_pass         = pick($facts['nagios_admin_password'], 'ExamPortal@2026')

  package { ['nagios4', 'nagios-plugins', 'nagios-nrpe-plugin', 'apache2', 'apache2-utils', 'libapache2-mod-php']:
    ensure => installed,
  }

  # Enable required Apache modules for Nagios 4 web dashboard
  exec { 'enable_nagios_apache_modules':
    command => '/usr/sbin/a2enmod authz_groupfile auth_digest cgi',
    unless  => '/usr/sbin/apache2ctl -M | /bin/grep -q cgi_module',
    require => Package['apache2'],
    notify  => Service['apache2'],
  }

  # Set nagiosadmin Digest auth entry non-interactively (matches Ubuntu nagios4 AuthName "Nagios4")
  exec { 'set_nagios_admin_password':
    command => "/bin/bash -c 'HASH=$(printf \"nagiosadmin:Nagios4:${admin_pass}\" | /usr/bin/md5sum | /usr/bin/awk \"{print \\$1}\"); printf \"nagiosadmin:Nagios4:%s\\n\" \"\$HASH\" > /etc/nagios4/htdigest.users'",
    require => Package['nagios4'],
    notify  => Service['apache2'],
  }

  # Deploy Nagios host & service checks when exam season is active
  file { '/etc/nagios4/conf.d/portal_host.cfg':
    ensure  => $exam_season_active ? { true => file, default => absent },
    content => template('nagios_server/portal_host.cfg.erb'),
    mode    => '0644',
    require => Package['nagios4'],
    notify  => Service['nagios4'],
  }

  service { 'apache2':
    ensure  => running,
    enable  => true,
    require => Package['apache2'],
  }

  service { 'nagios4':
    ensure  => running,
    enable  => true,
    require => [Package['nagios4'], File['/etc/nagios4/conf.d/portal_host.cfg']],
  }
}
````

## `puppet/modules/nagios_server/templates/portal_host.cfg.erb`

````text
# Managed by Puppet - Nagios 4 Monitoring Config for University Result Portal

define command {
    command_name    check_nrpe_portal
    command_line    /usr/lib/nagios/plugins/check_nrpe -H $HOSTADDRESS$ -c $ARG1$
}

define host {
    use                     generic-host
    host_name               university-result-portal
    alias                   University Student Result Portal
    address                 <%= @portal_ip %>
    max_check_attempts      3
    check_period            24x7
    notification_interval   15
    notification_period     24x7
}

define service {
    use                     generic-service
    host_name               university-result-portal
    service_description     Portal HTTP Availability
    check_command           check_http!-u /health.html -e 200
    check_interval          1
    retry_interval          1
}

define service {
    use                     generic-service
    host_name               university-result-portal
    service_description     Portal HTTPS SSL Endpoint
    check_command           check_http!-S -p 443 -u /health.html
    check_interval          2
    retry_interval          1
}

define service {
    use                     generic-service
    host_name               university-result-portal
    service_description     Portal RAM Usage
    check_command           check_nrpe_portal!check_portal_ram
    check_interval          1
    retry_interval          1
}

define service {
    use                     generic-service
    host_name               university-result-portal
    service_description     Portal Server Load
    check_command           check_nrpe_portal!check_portal_load
    check_interval          1
    retry_interval          1
}

define service {
    use                     generic-service
    host_name               university-result-portal
    service_description     Portal Root Disk Usage
    check_command           check_nrpe_portal!check_portal_disk
    check_interval          2
    retry_interval          1
}

define service {
    use                     generic-service
    host_name               university-result-portal
    service_description     Nginx Web Process
    check_command           check_nrpe_portal!check_portal_nginx
    check_interval          1
    retry_interval          1
}
````

## `nagios/portal_host.cfg`

````text
# Reference Nagios 4 Configuration for University Student Result Portal
# (Deployed automatically to /etc/nagios4/conf.d/portal_host.cfg by Puppet)

define command {
    command_name    check_nrpe_portal
    command_line    /usr/lib/nagios/plugins/check_nrpe -H $HOSTADDRESS$ -c $ARG1$
}

define host {
    use                     generic-host
    host_name               university-result-portal
    alias                   University Student Result Portal
    address                 <PORTAL_SERVER_PRIVATE_IP>
    max_check_attempts      3
    check_period            24x7
    notification_interval   15
    notification_period     24x7
}

define service {
    use                     generic-service
    host_name               university-result-portal
    service_description     Portal HTTP Availability
    check_command           check_http!-u /health.html -e 200
    check_interval          1
    retry_interval          1
}

define service {
    use                     generic-service
    host_name               university-result-portal
    service_description     Portal HTTPS SSL Endpoint
    check_command           check_http!-S -p 443 -u /health.html
    check_interval          2
    retry_interval          1
}

define service {
    use                     generic-service
    host_name               university-result-portal
    service_description     Portal RAM Usage
    check_command           check_nrpe_portal!check_portal_ram
    check_interval          1
    retry_interval          1
}

define service {
    use                     generic-service
    host_name               university-result-portal
    service_description     Portal Server Load
    check_command           check_nrpe_portal!check_portal_load
    check_interval          1
    retry_interval          1
}

define service {
    use                     generic-service
    host_name               university-result-portal
    service_description     Portal Root Disk Usage
    check_command           check_nrpe_portal!check_portal_disk
    check_interval          2
    retry_interval          1
}

define service {
    use                     generic-service
    host_name               university-result-portal
    service_description     Nginx Web Process
    check_command           check_nrpe_portal!check_portal_nginx
    check_interval          1
    retry_interval          1
}
````

## `portal-app/index.html`

````html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>University Exam & Result Portal</title>
  <style>
    :root {
      --primary: #1e3a8a;
      --accent: #2563eb;
      --bg: #f1f5f9;
      --card: #ffffff;
      --text: #0f172a;
      --muted: #64748b;
      --ok: #15803d;
      --err: #b91c1c;
    }
    * { box-sizing: border-box; font-family: system-ui, -apple-system, Segoe UI, Roboto, sans-serif; }
    body { margin: 0; background: var(--bg); color: var(--text); }
    header {
      background: var(--primary);
      color: #fff;
      padding: 1.25rem 2rem;
      display: flex;
      justify-content: space-between;
      align-items: center;
      flex-wrap: wrap;
      gap: 0.75rem;
    }
    header h1 { margin: 0; font-size: 1.35rem; }
    .badge {
      background: rgba(255,255,255,0.16);
      padding: 0.35rem 0.75rem;
      border-radius: 999px;
      font-size: 0.85rem;
    }
    main {
      max-width: 760px;
      margin: 2rem auto;
      padding: 0 1rem;
    }
    .card {
      background: var(--card);
      border-radius: 12px;
      padding: 1.75rem;
      box-shadow: 0 4px 16px rgba(15, 23, 42, 0.06);
      margin-bottom: 1.5rem;
    }
    .form-row {
      display: grid;
      grid-template-columns: 1fr 1fr auto;
      gap: 0.75rem;
      margin-top: 1rem;
    }
    @media (max-width: 640px) {
      .form-row { grid-template-columns: 1fr; }
    }
    input, select, button {
      padding: 0.7rem 0.9rem;
      border-radius: 8px;
      border: 1px solid #cbd5e1;
      font-size: 0.95rem;
    }
    button {
      background: var(--accent);
      color: #fff;
      border: none;
      font-weight: 600;
      cursor: pointer;
    }
    button:hover { background: #1d4ed8; }
    table {
      width: 100%;
      border-collapse: collapse;
      margin-top: 1rem;
    }
    th, td {
      text-align: left;
      padding: 0.65rem 0.75rem;
      border-bottom: 1px solid #e2e8f0;
    }
    th { color: var(--muted); font-size: 0.85rem; text-transform: uppercase; }
    .status-pass { color: var(--ok); font-weight: 700; }
    .status-fail { color: var(--err); font-weight: 700; }
    .hint { color: var(--muted); font-size: 0.88rem; margin-top: 0.6rem; }
  </style>
</head>
<body>
  <header>
    <h1>State University â€” Exam &amp; Result Portal</h1>
    <span class="badge">Managed by Terraform â€¢ Puppet â€¢ Nagios</span>
  </header>

  <main>
    <section class="card">
      <h2 style="margin-top:0;">Check Semester Results</h2>
      <p style="color:var(--muted); margin-top:0.25rem;">
        Enter your university roll number and semester to view published marks.
      </p>

      <form id="resultForm" class="form-row">
        <input id="rollInput" type="text" placeholder="Roll No (e.g. CS202601)" required />
        <select id="semInput">
          <option value="Sem-6">Semester 6</option>
          <option value="Sem-5">Semester 5</option>
        </select>
        <button type="submit">View Result</button>
      </form>
      <p class="hint">Sample Roll Numbers: <strong>CS202601</strong>, <strong>CS202602</strong>, <strong>EC202610</strong></p>
    </section>

    <section id="resultCard" class="card" style="display:none;">
      <h3 id="studentMeta" style="margin-top:0;"></h3>
      <table>
        <thead>
          <tr>
            <th>Subject</th>
            <th>Marks</th>
            <th>Grade</th>
            <th>Status</th>
          </tr>
        </thead>
        <tbody id="marksBody"></tbody>
      </table>
      <p id="sgpaLine" style="font-weight:700; margin-bottom:0;"></p>
    </section>
  </main>

  <script>
    const SAMPLE_RESULTS = {
      "CS202601": {
        name: "Aarav Sharma",
        branch: "Computer Science",
        sgpa: "8.9 / 10",
        subjects: [
          { name: "Cloud Computing & DevOps", marks: 91, grade: "A+", status: "PASS" },
          { name: "Distributed Systems", marks: 86, grade: "A", status: "PASS" },
          { name: "Computer Networks", marks: 84, grade: "A", status: "PASS" }
        ]
      },
      "CS202602": {
        name: "Priya Verma",
        branch: "Computer Science",
        sgpa: "9.3 / 10",
        subjects: [
          { name: "Cloud Computing & DevOps", marks: 95, grade: "O", status: "PASS" },
          { name: "Distributed Systems", marks: 90, grade: "A+", status: "PASS" },
          { name: "Computer Networks", marks: 89, grade: "A+", status: "PASS" }
        ]
      },
      "EC202610": {
        name: "Rohan Mehta",
        branch: "Electronics & Comm.",
        sgpa: "7.8 / 10",
        subjects: [
          { name: "Embedded Systems", marks: 79, grade: "B+", status: "PASS" },
          { name: "Digital Signal Processing", marks: 74, grade: "B", status: "PASS" },
          { name: "VLSI Design", marks: 81, grade: "A", status: "PASS" }
        ]
      }
    };

    document.getElementById("resultForm").addEventListener("submit", function (e) {
      e.preventDefault();
      const roll = document.getElementById("rollInput").value.trim().toUpperCase();
      const sem = document.getElementById("semInput").value;
      const card = document.getElementById("resultCard");
      const meta = document.getElementById("studentMeta");
      const body = document.getElementById("marksBody");
      const sgpa = document.getElementById("sgpaLine");

      const record = SAMPLE_RESULTS[roll];
      card.style.display = "block";
      body.innerHTML = "";

      if (!record) {
        meta.textContent = `No record found for Roll No: ${roll} (${sem})`;
        sgpa.textContent = "";
        return;
      }

      meta.textContent = `${record.name} â€¢ ${roll} â€¢ ${record.branch} (${sem})`;
      record.subjects.forEach((s) => {
        const tr = document.createElement("tr");
        tr.innerHTML = `
          <td>${s.name}</td>
          <td>${s.marks}</td>
          <td>${s.grade}</td>
          <td class="${s.status === "PASS" ? "status-pass" : "status-fail"}">${s.status}</td>
        `;
        body.appendChild(tr);
      });
      sgpa.textContent = `SGPA: ${record.sgpa}`;
    });
  </script>
</body>
</html>
````

## `portal-app/health.html`

````html
OK - University Result Portal Healthy
````

