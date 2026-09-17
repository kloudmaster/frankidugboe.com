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

### WAF — revisit in Phase E (contact backend)

- **`CKV_AWS_68` / Trivy `AWS-0011` — CloudFront WAF.** A WAF adds little value
  ahead of a pure static S3 origin with no compute. It becomes worthwhile once
  the API Gateway/Lambda contact backend exists, where it will be placed to
  protect an actual request-processing surface.
- **`CKV2_AWS_47` — Log4j AMR on the CloudFront WAF ACL.** Depends on the WAF
  above; deferred with it.

### Observability — Phase F

- **`CKV_AWS_86` — CloudFront access logging.**
- **`CKV_AWS_18` — S3 server access logging.**
- **`CKV2_AWS_39` — Route 53 DNS query logging.**

  These require dedicated log-destination bucket(s) that must themselves be
  governed (a log bucket triggers its own scanner findings). They belong to
  the observability phase and are deferred together to avoid premature
  infrastructure sprawl driven by the scanner rather than by need.

### DNSSEC — post-launch

- **`CKV2_AWS_38` — Route 53 DNSSEC signing.** Genuine hardening, but moderate
  effort (KMS key + key-signing key + parent DS record at the registrar).
  Scheduled post-launch.

## Review cadence

Deferred items should be revisited at their named phase:

1. **Phase E** (contact backend): remove `CKV_AWS_68`, `CKV2_AWS_47` and Trivy
   `AWS-0011` from the ignore lists and place a WAF in front of the API.
2. **Phase F** (observability): remove `CKV_AWS_86`, `CKV_AWS_18`,
   `CKV2_AWS_39` and implement logging with a governed log bucket.
3. **Post-launch**: remove `CKV2_AWS_38` and implement DNSSEC.

Accepted-risk and not-applicable waivers should be re-confirmed whenever the
architecture materially changes (for example, if the origin ever stores
non-public or sensitive data, revisit the KMS decision).

## Promoting the required check

Once the `IaC security checks` job passes on a run against the target branch,
it can be added to the `main` branch protection required-status-checks set
alongside `Frontend quality checks` and `Terraform validate and plan`.
