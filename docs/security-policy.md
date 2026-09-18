# IaC Security Scanner Policy

This document records the deliberate policy behind every Checkov and Trivy
finding for the portfolio infrastructure. The goal is a green
`IaC security checks` CI job that reflects real decisions — not findings
suppressed to chase a badge.

Scanners and pinned versions (matching CI):

- Checkov `3.3.18` — `checkov -d infrastructure --framework terraform`
- Trivy `0.74.0` — `trivy config infrastructure --severity HIGH,CRITICAL`
- TFLint `0.64.0` (passes with no findings)

Baseline before this policy: Checkov 63 passed / 18 failed; Trivy 3 HIGH.
After this policy: Checkov 67 passed / 0 failed; Trivy 0 findings.

Each finding is classified as **Implement**, **Waive** (false positive, not
applicable, or accepted risk), or **Defer** (valid, scheduled for a named
future phase). Suppressions live in `.checkov.yaml` and `.trivyignore`, each
with an inline comment pointing back to this document.

## Implemented

| Check | Resource(s) | Action |
| --- | --- | --- |
| `CKV2_AWS_61` S3 lifecycle configuration | origin bucket, state bucket | Added `aws_s3_bucket_lifecycle_configuration`: expire noncurrent versions (origin 30d, state 90d) and abort incomplete multipart uploads after 7d. Real cost control; no new resources or scanner recursion. |
| WAF on CloudFront (Phase E) | CloudFront distribution, contact API | Added a `CLOUDFRONT`-scoped WAFv2 Web ACL (`modules/waf`) with the AWS managed Common rule set, Known Bad Inputs rule set (Log4j coverage) and an IP rate-based rule, associated via `web_acl_id`. Protects the site and the contact API. |
| CloudFront access logging (Phase F, `CKV_AWS_86`) | CloudFront distribution | `logging_config` delivers access logs to the dedicated log bucket (`cloudfront/` prefix). |
| Route 53 query logging (Phase F, `CKV2_AWS_39`) | hosted zone | `aws_route53_query_log` to a us-east-1 CloudWatch log group with a resource policy for the Route 53 service. |
| WAF logging (Phase F, `CKV2_AWS_31`) | WAF Web ACL | `aws_wafv2_web_acl_logging_configuration` to an `aws-waf-logs-*` CloudWatch log group. |
| S3 origin access logging (Phase F, part of `CKV_AWS_18`) | origin bucket | `aws_s3_bucket_logging` to the dedicated log bucket. |
| Budget + alarms (Phase F) | account, contact Lambda | Monthly cost `aws_budgets_budget` with 80% actual + 100% forecasted email alerts, plus a Lambda-errors CloudWatch alarm, both via an (AWS-managed-KMS-encrypted) SNS topic. |

## Waived

### False positive

- **`CKV2_AWS_32` — CloudFront response headers policy.** The distribution
  attaches the AWS-managed `SecurityHeadersPolicy`
  (`67f7725c-6f97-4210-82d7-5512b31e9d03`) by ID, verified live at the public
  endpoint (HSTS, X-Frame-Options, etc. are served). Checkov's graph check
  only recognizes a policy provided as a `resource`/`data` source, not a
  managed policy referenced by ID — so this is a false positive.

### Not applicable to a single-origin static site

- **`CKV_AWS_310` — CloudFront origin failover.** Requires an origin group
  with 2+ origins. The site has one private S3 origin by design.
- **`CKV_AWS_374` — CloudFront geo restriction.** This is a public global
  professional portfolio; serving all geographies is intentional.
- **`CKV2_AWS_62` — S3 event notifications.** Neither the static origin bucket
  nor the state bucket has an event-driven consumer.

### Accepted risk

- **`CKV_AWS_144` — S3 cross-region replication.** Not warranted: the origin
  bucket is rebuilt from Git on every deploy and state is versioned and
  recoverable. CRR adds ongoing cost and a second bucket for no meaningful RPO
  gain at this scale.
- **`CKV_AWS_145` / Trivy `AWS-0132` — customer-managed KMS encryption.**
  Buckets use SSE-S3 (AES256). The origin holds only public static assets; the
  state bucket holds no secrets. SSE-S3 is sufficient; a customer-managed key
  adds key-management cost and complexity without a matching risk reduction.

## Deferred

### Observability — Phase F (implemented)

CloudFront access logging (`CKV_AWS_86`), Route 53 query logging
(`CKV2_AWS_39`) and WAF logging (`CKV2_AWS_31`) are implemented and no longer
waived. The remaining logging-related waivers are:

- **`CKV_AWS_18` — S3 server access logging.** Implemented on the origin bucket
  (delivers to the dedicated log bucket). Still waived because the check also
  flags the Terraform state bucket (low-traffic, Terraform-only) and the log
  bucket itself (a log bucket cannot log to itself). Those two are intentionally
  excluded.
- **`CKV2_AWS_65` — S3 ACLs should be disabled.** The dedicated log bucket must
  enable ACLs (`BucketOwnerPreferred`) because CloudFront standard logging and
  S3 server access log delivery require the log-delivery ACL grant. All other
  buckets keep `BucketOwnerEnforced`, and the log bucket still blocks all public
  access.
- **Trivy `AWS-0136` — SNS customer-managed KMS key.** The alerts topic carries
  only budget/alarm notifications and uses the AWS-managed SNS key; a CMK adds
  cost/complexity for no meaningful gain, consistent with the SSE-S3 decision.

### DNSSEC — post-launch

- **`CKV2_AWS_38` — Route 53 DNSSEC signing.** Genuine hardening, but moderate
  effort (KMS key + key-signing key + parent DS record at the registrar).
  Scheduled post-launch.

## Contact backend (Phase E)

The API Gateway -> Lambda -> SES contact backend and its CloudFront WAF added
new checks. Classifications:

### False positive — WAF attached but not statically resolvable

- **`CKV_AWS_68` / `CKV2_AWS_47` / Trivy `AWS-0011`.** The distribution attaches
  a WAFv2 Web ACL via `module.waf` -> `web_acl_id`, including Known Bad Inputs
  (Log4j) coverage. Because the association is a cross-module variable
  reference, not a literal, the scanners' static graphs cannot resolve it.

### Not applicable to a simple first-party contact function

- **`CKV_AWS_116`** Lambda DLQ — synchronous handler returns errors to caller.
- **`CKV_AWS_117`** Lambda in VPC — only calls the public SES API.
- **`CKV_AWS_272`** Lambda code signing — single first-party function.
- **`CKV_AWS_309`** API route authorization — the contact endpoint is
  intentionally public; abuse is handled by WAF + honeypot + rate limiting.
- **`CKV2_AWS_31`** WAF logging — needs a log destination; deferred to Phase F.

### Accepted risk — consistent with the SSE-S3 / retention decisions

- **`CKV_AWS_158`** CloudWatch log group KMS — logs hold no secrets.
- **`CKV_AWS_173`** Lambda env var KMS — AWS-managed key encryption is default.
- **`CKV_AWS_338`** one-year log retention — 30 days is a deliberate cost choice.

## Review cadence

Deferred items should be revisited at their named phase:

1. **Post-launch**: remove `CKV2_AWS_38` and implement DNSSEC.

Phases E (contact backend + WAF) and F (observability, logging, budget) are
implemented; their remaining entries above are permanent waivers (false
positives, not-applicable, or accepted risk), not deferrals.

Accepted-risk and not-applicable waivers should be re-confirmed whenever the
architecture materially changes (for example, if the origin ever stores
non-public or sensitive data, revisit the KMS decision).

## Promoting the required check

Once the `IaC security checks` job passes on a run against the target branch,
it can be added to the `main` branch protection required-status-checks set
alongside `Frontend quality checks` and `Terraform validate and plan`.
