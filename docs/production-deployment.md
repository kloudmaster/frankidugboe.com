# Production Deployment Setup

This document covers the one-time GitHub configuration required for
`.github/workflows/deploy.yml` to run. These steps are applied in the
GitHub web UI; they are not managed by Terraform.

## Overview

`deploy.yml` runs on every push to `main` (and manual `workflow_dispatch`).
It authenticates to AWS through GitHub OIDC by assuming the deploy role,
runs `terraform apply`, builds the Astro site, syncs it to the private S3
origin, invalidates CloudFront, and runs an HTTPS smoke test.

The deploy role's trust policy only permits the OIDC subject
`...:environment:production`. Therefore the workflow **must** run in a GitHub
Environment named exactly `production`, or the `AssumeRoleWithWebIdentity`
call will be rejected.

## 1. Repository variables

Create these as **repository variables** (not secrets — they are not
sensitive). Settings -> Secrets and variables -> Actions -> Variables tab ->
New repository variable.

| Name                  | Value                                                              |
| --------------------- | ------------------------------------------------------------------ |
| `AWS_REGION`          | `us-east-1`                                                        |
| `AWS_DEPLOY_ROLE_ARN` | `arn:aws:iam::216066926519:role/frankidugboe-com-github-deploy`   |

The plan workflow (`terraform-plan.yml`) currently hardcodes the plan role
and region. Optionally add `AWS_PLAN_ROLE_ARN` and switch that workflow to
`vars.*` for consistency, but that is not required for deploys.

## 2. Production environment

Settings -> Environments -> New environment -> name it exactly `production`.

Recommended protection rules:

- **Required reviewers**: add yourself (`kloudmaster`). This turns every
  production deploy into a manual approval gate — the workflow pauses after
  reaching the environment until approved. Strongly recommended for a
  single-maintainer production site.
- **Deployment branches**: restrict to `main` only, so the environment (and
  the deploy role it unlocks) can never be used from a feature branch.
- **Wait timer**: optional; leave at 0 unless you want a cool-down.

Environment-scoped variables are not required because `AWS_REGION` and
`AWS_DEPLOY_ROLE_ARN` are defined at the repository level and inherited.

## 3. First deploy

1. Merge `feature/portfolio-v1` into `main` (or run the workflow manually via
   Actions -> Production Deploy -> Run workflow).
2. If required reviewers are enabled, approve the run when it pauses at the
   `production` environment.
3. Watch the job. Expected sequence: OIDC auth -> terraform apply ->
   npm build -> two S3 sync passes -> CloudFront invalidation -> HTTPS smoke
   test returning `HTTP 200` with an `strict-transport-security` header.

## Contact backend (Phase E)

The contact form posts to `/api/contact`, routed by CloudFront to an API
Gateway HTTP API backed by a Lambda that sends mail via Amazon SES. Two manual
prerequisites apply:

### `SES_RECIPIENT` secret

The private inbox that receives contact submissions is never committed. Add it
as a GitHub Actions **secret** named `SES_RECIPIENT`; the deploy workflow passes
it to Terraform as `TF_VAR_ses_recipient` during `terraform apply`.

Settings -> Secrets and variables -> Actions -> Secrets -> New repository secret:

| Name            | Value                          |
| --------------- | ------------------------------ |
| `SES_RECIPIENT` | your private destination inbox |

The sender address defaults to `no-reply@frankidugboe.com` (the SES-verified
sending domain) and can be overridden via the `ses_sender` variable.

### SES sandbox

A new AWS account's SES is in the **sandbox**, which can only send to verified
addresses. Before the form can deliver to an arbitrary inbox:

- Verify the `SES_RECIPIENT` address in the SES console (sufficient if you only
  ever send to your own inbox), **or**
- Request SES production access (Account dashboard -> Request production access)
  to lift the sandbox restriction.

The sending domain's DKIM, SPF and custom MAIL FROM records are provisioned by
the `ses` Terraform module; DKIM verification can take time to propagate after
the first apply.

## DNSSEC (post-launch)

Terraform provisions Route 53 DNSSEC signing (KMS signing key + key-signing key
+ zone signing). Completing the chain of trust requires **one manual step at the
registrar** — Terraform cannot set records at Porkbun.

After the deploy that enables DNSSEC:

1. Read the DS record Terraform exposes:
   ```bash
   terraform -chdir=infrastructure/environments/production output dnssec_ds_record
   ```
   (The AWS console also shows it under Route 53 -> Hosted zones ->
   frankidugboe.com -> DNSSEC signing.)
2. In the Porkbun dashboard for frankidugboe.com, open the **DNSSEC** section and
   add a DS record using the values from that output (key tag, algorithm, digest
   type, and digest).
3. Allow time for propagation, then verify the chain of trust, e.g. with
   `dig +dnssec frankidugboe.com` or an online DNSSEC analyzer.

Do not enable DNSSEC at the registrar before the KSK is active in Route 53, and
do not remove the DS record while zone signing is enabled — a mismatch can make
the domain unresolvable for validating resolvers.

## Notes and design decisions

- **No invalidation wait**: the deploy role intentionally does not include
  `cloudfront:GetInvalidation`, so the workflow creates the invalidation but
  does not poll for completion. The HTTPS smoke test (with a retry loop) is
  what confirms the live site is healthy.
- **Cache headers and `--delete`**: the workflow syncs in three passes to set
  correct cache headers without stale content, because `aws s3 sync` decides
  what to upload from size + modified time only (it ignores metadata), and
  `--delete` only "sees" the filtered source view:
  1. `_astro/*` uploaded with `max-age=31536000, immutable` (content-hashed
     filenames, no `--delete`).
  2. Everything else (HTML, sitemap, robots, favicons) synced with
     `max-age=0, must-revalidate` and `--delete`, excluding `_astro/*` so the
     immutable assets are never deleted by this pass.
  3. The `_astro/` prefix is reconciled on its own with `--delete` so orphaned
     assets from previous builds are pruned while headers stay immutable.
  Each object is written exactly once with the correct header, and no pass can
  delete files another pass owns.
- **Concurrency**: `group: production-deploy` with `cancel-in-progress: false`
  ensures production deploys queue rather than overlap or get cancelled
  mid-apply.
