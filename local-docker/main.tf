terraform {
  required_version = ">= 1.5.0"

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {}

resource "docker_network" "portal_net" {
  name = "result-portal-net"
}

resource "docker_image" "portal_img" {
  name = "university-result-portal:latest"
  build {
    context    = abspath("${path.module}/..")
    dockerfile = "local-docker/Dockerfile.portal"
  }
}

resource "docker_image" "nagios_img" {
  name = "university-nagios-monitor:latest"
  build {
    context    = abspath("${path.module}/..")
    dockerfile = "local-docker/Dockerfile.nagios"
  }
}

resource "docker_container" "portal" {
  count    = var.exam_season_active ? 1 : 0
  name     = "portal-server"
  hostname = "portal-server"
  image    = docker_image.portal_img.image_id
  restart  = "unless-stopped"

  networks_advanced {
    name = docker_network.portal_net.name
  }

  ports {
    internal = 80
    external = var.portal_http_port
  }

  ports {
    internal = 443
    external = var.portal_https_port
  }
}

resource "docker_container" "nagios" {
  name     = "nagios-server"
  hostname = "nagios-server"
  image    = docker_image.nagios_img.image_id
  restart  = "unless-stopped"

  env = [
    "PORTAL_HOST=portal-server",
    "EXAM_SEASON_ACTIVE=${var.exam_season_active}",
    "NAGIOS_ADMIN_PASSWORD=${var.nagios_admin_password}",
    "ADMIN_EMAIL=${var.admin_email}",
    "ALERT_WEBHOOK_URL=${var.alert_webhook_url}"
  ]

  networks_advanced {
    name = docker_network.portal_net.name
  }

  ports {
    internal = 80
    external = var.nagios_http_port
  }

  depends_on = [docker_container.portal]
}
