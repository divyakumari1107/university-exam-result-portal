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

  user_data_base64 = base64gzip(templatefile("${path.module}/cloud-init/bootstrap_nagios.sh.tftpl", {
    nagios_admin_password = var.nagios_admin_password
    admin_email           = var.admin_email
    alert_webhook_url     = var.alert_webhook_url
    nagios_site_pp        = file("${path.module}/../puppet/manifests/site.pp")
    nagios_init_pp        = file("${path.module}/../puppet/modules/nagios_server/manifests/init.pp")
    nagios_host_cfg_erb   = file("${path.module}/../puppet/modules/nagios_server/templates/portal_host.cfg.erb")
    portal_private_ip     = var.exam_season_active ? aws_instance.portal_server[0].private_ip : "127.0.0.1"
    exam_season_active    = var.exam_season_active
  }))

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

  user_data_base64 = base64gzip(templatefile("${path.module}/cloud-init/bootstrap_portal.sh.tftpl", {
    portal_site_pp       = file("${path.module}/../puppet/manifests/site.pp")
    portal_init_pp       = file("${path.module}/../puppet/modules/portal_web/manifests/init.pp")
    portal_conf_erb      = file("${path.module}/../puppet/modules/portal_web/templates/portal.conf.erb")
    logrotate_erb        = file("${path.module}/../puppet/modules/portal_web/templates/logrotate_nginx.erb")
    nrpe_cfg_erb         = file("${path.module}/../puppet/modules/portal_web/templates/nrpe_portal.cfg.erb")
    portal_index_html    = base64encode(file("${path.module}/../portal-app/index.html"))
    portal_health        = base64encode(file("${path.module}/../portal-app/health.html"))
    portal_students_json = base64encode(file("${path.module}/../portal-app/students.json"))
  }))

  tags = {
    Name    = "university-result-portal"
    Role    = "webserver"
    Project = "UniversityResultPortal"
  }
}
