data "sops_file" "cf_secrets" {
  source_file = "cf.secrets.enc.json"
}