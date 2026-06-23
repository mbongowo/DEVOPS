# 04 · DevSecOps CI/CD Pipeline with Security Scanning

A **shift-left security pipeline** that blocks insecure builds. Every push runs
five classes of scan, each a hard gate, and publishes the reports as build
artifacts.

> **Inspiration & credit:** [`Jigyasusinghchouhan/End-to-End-DevSecOps-...-EKS-Terraform-Jenkins-ArgoCD`](https://github.com/Jigyasusinghchouhan/End-to-End-DevSecOps-Kubernetes-Project-using-AWS-EKS-with-Terraform-Jenkins-and-ArgoCD)
> and [`praduman8435/DevSecOps-in-Action`](https://github.com/praduman8435/DevSecOps-in-Action).
> Independent rebuild that favours **self-contained, server-free gates**
> (Semgrep, Trivy, gitleaks, Checkov) so the whole pipeline runs green in CI,
> with SonarQube and OWASP Dependency-Check wired in behind secrets.

## Security gates → risk

| Gate | Tool | Fails the build on | Risk mitigated |
|------|------|--------------------|----------------|
| **SAST** | Semgrep (`p/default`) | any code finding | injection, unsafe config, bad crypto |
| **Secrets** | gitleaks | a committed credential | leaked keys/tokens in git |
| **Dependencies / FS** | Trivy `fs` | HIGH/CRITICAL CVE, secret, or misconfig | vulnerable libraries, embedded secrets |
| **Container image** | Trivy `image` | fixable **CRITICAL** | exploitable base/app CVEs at runtime |
| **IaC** | Trivy `config` | HIGH/CRITICAL misconfig | insecure cloud resources (public S3, no encryption) |
| _SAST (alt)_ | SonarQube | quality gate | runs when `SONAR_TOKEN` is set |
| _Deps (alt)_ | OWASP Dependency-Check | CVSS ≥ 7 | runs when `NVD_API_KEY` is set |
| IaC (2nd opinion) | Checkov | informational (soft-fail) | broader policy coverage + report |

Reports for every gate upload as workflow **artifacts** (`*-report.json`).

## What's scanned

- `app/` — a small Flask service + hardened Dockerfile (base OS patched).
- `terraform/` — a deliberately hardened S3 bucket (CMK encryption + rotation,
  versioning, full public-access block).

## Demonstrate a gate catching a regression

Each gate passes on the clean code in this folder. To watch one **block** a build:

| Introduce… | Caught by |
|------------|-----------|
| `password = "hunter2"` in any file | gitleaks |
| `eval(request.args["x"])` in `app.py` | Semgrep |
| remove `aws_s3_bucket_public_access_block` | Trivy config |
| pin an old `Flask==2.0.0` | Trivy fs / OWASP DC |

## Run locally

```bash
gitleaks detect --no-git --source . --config .gitleaks.toml
semgrep scan --config p/default --error app/
docker build -t devsecops-demo:ci app && trivy image --severity CRITICAL --ignore-unfixed devsecops-demo:ci
trivy config --severity HIGH,CRITICAL terraform
checkov -d terraform
```

## Deploy (passing builds)

A build that clears every gate is promoted the GitOps way — Argo CD syncs the
image into EKS (see projects [`01`](../01-three-tier-devsecops-eks) and
[`03`](../03-sockshop-gitops)). Supply-chain controls (SBOM, signing, admission
policy) live in project [`07`](../07-supply-chain-security).
