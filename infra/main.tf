terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5"
    }
  }
}

# The Cloudflare API token needs a set of minimal permissions:
# 1. Zone Permissions (for DNS and domain lookup)
#    - Zone -> Read READ
#    - DNS -> Edit WRITE
# 2. Account Permissions (for creating Pages project)
#   - Pages -> Edit WRITE
provider "cloudflare" {
  api_token = "DUTJ7xDMy4s6aZL8_uu9vCrC3S7sYaZyPcSHCoS8"
}

variable "zone_id" {
  default = "32c9f795aed95c3cc06f1ef851bc7b15"
}

variable "account_id" {
  default = "746ea4a22edc1e6e7d78cfa8b896c09b"
}

variable "domain" {
  default = "valentin-roy.dev"
}

# https://cv-site-3jd.pages.dev/
resource "cloudflare_pages_project" "cv" {
  account_id = var.account_id
  name       = "cv-valentin"

  production_branch = "main"

  build_config = {
    build_command   = ""
    destination_dir = "/"
  }
}

resource "cloudflare_dns_record" "cv_dns" {
  zone_id = var.zone_id
  name    = "@"
  type    = "A"
  content = "192.0.2.1"
  ttl     = 1
  proxied = true
}

# Bind the domain to the Pages project
resource "cloudflare_pages_domain" "cv_domain" {
  account_id      = var.account_id
  project_name    = cloudflare_pages_project.cv.name
  name            = var.domain
}