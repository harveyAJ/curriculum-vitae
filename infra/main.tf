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

# Bind the domain to the Pages project (can be viewed in Cloudflare UI in Pages section "Custom domains")
# This will generate the CNAME target e.g. cv-valentin-abc.pages.dev
resource "cloudflare_pages_domain" "cv_domain" {
  account_id      = data.sops_file.cf_secrets.data["account_id"]
  project_name    = cloudflare_pages_project.cv.name
  name            = var.domain
}

resource "cloudflare_pages_domain" "cv_domain_www" {
  account_id   = data.sops_file.cf_secrets.data["account_id"]
  project_name = cloudflare_pages_project.cv.name
  name         = "www.${var.domain}"
}

locals {
  pages_cname_target = cloudflare_pages_project.cv.subdomain
}

# Apex domain
resource "cloudflare_dns_record" "apex" {
  zone_id = data.sops_file.cf_secrets.data["zone_id"]
  name    = var.domain
  type    = "CNAME"
  content = local.pages_cname_target
  ttl     = 1
  proxied = true
}

# www domain
resource "cloudflare_dns_record" "www" {
  zone_id = data.sops_file.cf_secrets.data["zone_id"]
  name    = "www"
  type    = "CNAME"
  content = local.pages_cname_target
  ttl     = 1
  proxied = true
}

# Redirect www.valentin-roy.dev to https://valentin-roy.dev
# A redirect is recommended so search engine treat these two as one site (SEO best practices)
# TODO this doesn't seem to work via tf, getting error `phase "http_request_redirect" not allowed at zone level` when applying
resource "cloudflare_ruleset" "www_to_root_redirect" {
  zone_id = data.sops_file.cf_secrets.data["zone_id"]
  name    = "Redirect www to root"
  kind    = "zone"
  phase   = "http_request_redirect"

  rules = [{
    ref = "redirect_www_to_root"
    action = "redirect"
    description = "Redirect www to root"
    enabled = true

    # Match only the www subdomain
    expression = "(http.host eq \"www.${var.domain}\")"

    action_parameters = {
      from_value = {
        status_code = 301
        target_url  = {
          value = "https://${var.domain}${"$${uri}"}"
        }
        preserve_query_string = true #ensures ?a=b stays attached
      }
    }
  }
  ]
}