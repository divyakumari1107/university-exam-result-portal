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
