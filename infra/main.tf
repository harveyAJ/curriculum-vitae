terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5"
    }

    sops = {
      source  = "carlpett/sops"
      version = "~> 1.0"
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
  api_token = data.sops_file.cf_secrets.data["api_token"]
}

# https://cv-site-3jd.pages.dev/
resource "cloudflare_pages_project" "cv" {
  account_id = data.sops_file.cf_secrets.data["account_id"]
  name       = "cv-valentin"

  production_branch = "main"

  build_config = {
    build_command   = ""
    destination_dir = "/"
  }
}

# TODO add a CNAME for www here too?
resource "cloudflare_dns_record" "cv_dns" {
  zone_id = data.sops_file.cf_secrets.data["zone_id"]
  name    = "@"
  type    = "A"
  content = "192.0.2.1"
  ttl     = 1
  proxied = true
}

# Bind the domain to the Pages project
resource "cloudflare_pages_domain" "cv_domain" {
  account_id      = data.sops_file.cf_secrets.data["account_id"]
  project_name    = cloudflare_pages_project.cv.name
  name            = var.domain
}