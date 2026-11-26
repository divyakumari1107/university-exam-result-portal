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

variable "admin_email" {
  description = "University IT Admin email for Nagios alerts"
  type        = string
  default     = "admin@university.local"
}

variable "alert_webhook_url" {
  description = "Optional Slack, Discord, or Telegram Bot API webhook URL for Nagios alerts"
  type        = string
  sensitive   = true
  default     = ""
}
