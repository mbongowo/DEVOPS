# 07 — Software Supply-Chain Security

End-to-end supply-chain controls for a container image: **generate an SBOM,
scan it, sign the image, attach the SBOM as an attestation, and enforce an
admission policy that only lets signed, scanned images run.** The whole flow is
verified in CI hermetically — no external registry, no stored secrets, no
cluster required.

```
 build ──▶ SBOM (Syft) ──▶ scan (Grype, fail on Critical)
   │
   └─▶ push ──▶ sign (Cosign) ──▶ attest SBOM (Cosign) ──▶ verify ✓
                                                            unsigned ✗ (rejected)
 Kyverno policy ──▶ admit signed+scanned  /  block unsigned, :latest, root
```

## The application (`app/`)

A tiny Go HTTP service with **no third-party dependencies**, built multi-stage
into `gcr.io/distroless/static:nonroot` — no shell, no package manager, runs as
non-root. The only code in the image is our static binary plus the Go standard
library, which keeps the vulnerability surface minimal.

> The Go **toolchain** version is a real input to the scan: a compiled binary
> carries the stdlib of the Go version that built it, and stdlib CVEs show up in
> Grype. The builder is pinned to `golang:1.25-alpine` to clear known criticals;
> it must track Go security releases (same treadmill as any base image).

## Controls

### 1. SBOM + vulnerability scan (`build-scan` job)
- **Syft** generates an SBOM in both **SPDX** and **CycloneDX** JSON (uploaded as a build artifact).
- **Grype** scans the SBOM and **fails the build on any Critical** finding.

### 2. Sign + attest + verify (`sign-verify` job)
Fully hermetic: a `registry:2` **service container** stands in for a real
registry, and an **ephemeral key pair** is generated per run (no secrets).
- `cosign sign` signs the image **by digest**.
- `cosign attest` attaches the **SBOM as an SPDX attestation**.
- `cosign verify` + `cosign verify-attestation` prove the signed image passes.
- A **negative test** builds a second, unsigned image and asserts that
  `cosign verify` **rejects** it — the exact control Kyverno enforces at admission.

Cosign v3 removed `--tlog-upload=false`; offline signing uses a signing-config
with the transparency-log and timestamp services stripped
(`jq 'del(.rekorTlogUrls) | del(.timestampAuthorityUrls)'`), and verification
passes `--insecure-ignore-tlog=true`.

### 3. Admission policy (`policy/`, `policy` job)
Three Kyverno `ClusterPolicy` objects:

| Policy | Effect |
|--------|--------|
| `verify-images.yaml` | Admit Pods only if the image carries a valid **keyless Cosign signature** from this repo's workflow identity (the production control). |
| `disallow-latest-tag.yaml` | Reject mutable `:latest` tags (digests can't be pinned otherwise). |
| `require-non-root.yaml` | Require `securityContext.runAsNonRoot: true`. |

`kyverno test policy/tests` runs a deterministic **block-vs-admit** suite
(`good-app` passes; `bad-latest` and `bad-root` are rejected by the right
policy) — 6 assertions, no cluster needed. `kubeconform` schema-validates all
three policies against the Kyverno CRD schemas.

## CI (`.github/workflows/supply-chain.yml`)

Three jobs, all hermetic and deterministic: **build-scan**, **sign-verify**,
**policy**. No registry credentials, no `id-token`, no cluster.

## Production path: keyless signing + live enforcement

The hermetic CI proves the mechanics with a key pair. In production you'd sign
**keyless** with the workflow's OIDC identity and enforce on a real cluster —
which is exactly what `verify-images.yaml` is written for:

```bash
# Keyless sign in CI (needs: permissions: id-token: write, packages: write)
cosign sign --yes ghcr.io/mbongowo/devops/supply-chain-demo@${DIGEST}
cosign attest --yes --type spdxjson --predicate sbom.spdx.json \
  ghcr.io/mbongowo/devops/supply-chain-demo@${DIGEST}

# Live enforcement demo on a kind cluster
kind create cluster
helm install kyverno kyverno/kyverno -n kyverno --create-namespace
kubectl apply -f policy/verify-images.yaml
kubectl run good --image=ghcr.io/mbongowo/devops/supply-chain-demo@${DIGEST}  # admitted
kubectl run bad  --image=nginx:latest                                         # blocked
```

## Run it locally

```bash
docker build -t supply-chain-demo:ci --build-arg VERSION=ci app
syft supply-chain-demo:ci -o spdx-json=sbom.spdx.json
grype sbom:sbom.spdx.json --fail-on critical
kyverno test policy/tests
```
