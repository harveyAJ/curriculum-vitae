# My CV

Meant to host this on an S3 bucket (thought that'd be more fun?) but ended up hosting in Cloudflare, for simplicity (and £££ savings). There is also good support in Terraform for Cloudflare, so all good.

Built using the (free) StartBootstrap 'Resume' theme

I'm using manual deploy with wrangler CLI as opposed to GitHub integration in Cloudflare

# Deploy manually to Cloudflare

First, as a prerequisite:

```
npm install -g wrangler
```

Then deploy the static assets as a Pages deployment

```
wrangler pages deploy . --project-name=cv-site
```



# SOPS

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

SOPS will look for a text file name `keys.txt` located in `~/Library/Application Support/sops/age/keys.txt` on MacOS for decryption, so move this file we just created in this folder.

The other option (that you will need when running Terraform locally) is to set the following environment variable

```sh
export SOPS_AGE_KEY_FILE=~/Library/Application Support/sops/age/keys.txt
```

Then encrypt with the public key (in the `.sops.yaml` config file)

```
asdf exec  sops -e --verbose --config ./.sops.yaml  secrets.json > cf.secrets.enc.json
```

# ASDF

Version management to enforce specific versions of terraform and sops.

Overkill here, it's just an example for me for future reference.