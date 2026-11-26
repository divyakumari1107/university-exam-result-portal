output "portal_url" {
  description = "Local URL for the Student Result Portal"
  value       = var.exam_season_active ? "http://localhost:${var.portal_http_port}" : "Portal container scaled down (exam_season_active = false)"
}

output "nagios_dashboard_url" {
  description = "Local URL for the Nagios 4 dashboard (login: nagiosadmin)"
  value       = "http://localhost:${var.nagios_http_port}/nagios4"
}
