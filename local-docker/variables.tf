variable "exam_season_active" {
  description = "Toggle on-demand exam portal container provisioning"
  type        = bool
  default     = true
}

variable "portal_http_port" {
  description = "Local host port mapped to the Student Result Portal HTTP port"
  type        = number
  default     = 8080
}

variable "portal_https_port" {
  description = "Local host port mapped to the Student Result Portal HTTPS port"
  type        = number
  default     = 8443
}

variable "nagios_http_port" {
  description = "Local host port mapped to the Nagios 4 dashboard"
  type        = number
  default     = 8081
}

variable "nagios_admin_password" {
  description = "Password for Nagios web dashboard (username: nagiosadmin)"
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
