# frankidugboe.com

Personal portfolio site of Frank Osasere Idugboe — Cloud & DevOps Engineer.

Live at **https://frankidugboe.com**.

The site is a fast static website with a working contact form. It runs on AWS,
and all the infrastructure is defined in code and deployed automatically.

## What's in here

- `app/` — the website (Astro, TypeScript, Tailwind CSS)
- `functions/contact/` — the contact form's backend function
- `infrastructure/` — all the AWS setup, written in Terraform
- `docs/` — setup and security notes
- `.github/workflows/` — the automated build, test, and deploy pipelines

## How it works

- The website is built as static files and served through a CDN (CloudFront)
  from a private storage bucket (S3). Visitors always get HTTPS.
- The contact form sends messages through a small serverless function, which
  emails them to a private inbox. The email address is never shown publicly.
- A firewall (WAF) sits in front of the site and the form to block abuse.
- Every change is checked and tested automatically before it can go live, and
  deploys happen on their own after a change is merged.

## Working on the site

Requires Node.js 24 (see `.nvmrc`).

```bash
cd app
npm install
npm run dev      # local preview
npm run build    # production build
npm test         # run tests
```

## Working on the infrastructure

Requires Terraform 1.16.3 (see `.terraform-version`).

```bash
cd infrastructure/environments/production
terraform init
terraform plan
```

Local runs use the `frank-portfolio` AWS profile; the automated pipeline uses
secure short-lived credentials instead of stored keys.

## Deploying

Merging to the `main` branch triggers the deploy pipeline, which builds the
site, updates the infrastructure, publishes the files, and runs a quick health
check. Production deploys wait for manual approval before running.

## Security and quality

Every change runs through automated checks: website tests, infrastructure
validation and tests, and security scans. The site uses HTTPS, security
response headers, DNSSEC, access logging, and a monthly cost alert. Decisions
about the security scan results are written down in `docs/security-policy.md`.

## Notes

- `docs/production-deployment.md` — how the deploy pipeline and one-time setup work
- `docs/security-policy.md` — the security decisions behind the project

Built with Astro, Terraform, GitHub Actions, and AWS.
