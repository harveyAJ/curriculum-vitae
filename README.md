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
- Creates redirects (www -> root)

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

## To-do

- Make this an angular app?