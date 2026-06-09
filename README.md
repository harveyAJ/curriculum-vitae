# My CV

I'm using this as a playground for trying out a few technologies. Sure, using Terraform to deploy my cv to a Cloudflare Pages site is overkill, but it's also fun :)

I initially meant to host this on an S3 bucket (thought that'd be more fun?) but ended up hosting in Cloudflare, for simplicity (and £££ savings). There is also good support in Terraform for Cloudflare, so all good.

Built using the (free) StartBootstrap 'Resume' theme.

I'm using manual deploy with wrangler CLI as opposed to GitHub integration in Cloudflare (again, not exactly for practicality)

## Manual deployment

First, as a prerequisite:

```
npm install -g wrangler
```

Then deploy the static assets as a Pages deployment

```
wrangler pages deploy . --project-name=cv-site
```

(The pipeline `deploy.yml` does that automatically upon pushes to main).

## Cloudflare

The API token for cloudflare eventually expires so needs to be re-generated (and sops file edited accordingly)
This is the set of minimal permissions needed to create the infra on Cloudflare using Terraform:
- Zone Permissions (for DNS and domain lookup)
  - Zone -> Read READ
  - DNS -> Edit WRITE
- Account Permissions (for creating Pages project)
  - Pages -> Edit WRITE

## Terraform

Deploy the site to Cloudflare:
- Creates the Pages project
- Creates relevant DNS records (A, AAAA, CNAME)
- ~~Creates redirects (www -> root)~~ Actually, I couldn't do it via tf, kept getting the error `phase \"http_request_redirect\" not allowed at zone level` when applying the ruleset. Instead I'm using the `_redirects` file. Less cool than using tf to do that but at least it works

I cheated a bit and added the custom domain www.valentin-roy.dev manually using Cloudflare UI.

But in theory Terraform should have taken care of it (only added the relevant block _after_)

```tf
resource "cloudflare_pages_domain" "cv_domain_www" {
  account_id   = data.sops_file.cf_secrets.data["account_id"]
  project_name = cloudflare_pages_project.cv.name
  name         = "www.${var.domain}"
}
```

## SOPS

I've encrypted Cloudflare's secrets using `sops` and `age`. Refer to this section should any of the CF secrets be rotated (API token, zone ID or account ID)

Create a `secrets.json` file

```json
{
    "api_token": "XXX",
    "zone_id": "XXX",
    "account_id": "XXX"
}
```

Generate public private age key pair like so:

```
age-keygen -o keys.txt
```

**Note**

"Error decrypting sops file"

SOPS will look for a text file name `keys.txt` located in `~/.config/sops/age/keys.txt` on MacOS for decryption, so move this file we just created in this folder.

It looks like you also need to setup this environment variable:

```sh
export SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt
```

Then encrypt with the public key (in the `.sops.yaml` config file)

```
asdf exec  sops -e --verbose --config ./.sops.yaml  secrets.json > cf.secrets.enc.json
```

## ASDF

Version management to enforce specific versions of terraform and sops.

Overkill here, it's just an example for me for future reference.

## Git

I recently switched from https to ssh for pushing changes. Should you push changes from a different machine, new SSH key will have to be generate  and `~/.ssh/config` will have to be updated (and public key added to GitHub). Instructions [here](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent)

## To-do

- Make this an angular app?
- Allow pipeline to be run manually
- Get terraform to register custom domain www.valentin-roy.dev? Is this possible?
