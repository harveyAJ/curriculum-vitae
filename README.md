# My CV

Hosted in Cloudflare.

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