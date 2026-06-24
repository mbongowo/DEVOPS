# DEVOPS — 15 projects

A monorepo of hands-on DevOps projects, each self-contained in its own
directory and validated by its own CI pipeline. It holds two collections:

- **Foundations (8 projects)** — take an application from source to a
  monitored, GitOps-managed deployment (CI/CD, Terraform, Helm, Argo CD,
  observability, Compose, Ansible, a custom Action).
- **AWS cloud-native & DevSecOps wave (7 projects, `01`–`07`)** — EKS, GitOps,
  observability, shift-left security, and supply-chain hardening on AWS.
  **Validate-only**: scaffolded and checked locally and in CI (`terraform
  validate`, kind, kubeconform, policy tests) — never applied to live AWS, so
  there is no cloud spend.

Fifteen path-filtered pipelines build and validate independently on every push.

## Foundations

[![petclinic](https://github.com/mbongowo/DEVOPS/actions/workflows/petclinic.yml/badge.svg)](https://github.com/mbongowo/DEVOPS/actions/workflows/petclinic.yml)
[![Terraform](https://github.com/mbongowo/DEVOPS/actions/workflows/terraform.yml/badge.svg)](https://github.com/mbongowo/DEVOPS/actions/workflows/terraform.yml)
[![Helm](https://github.com/mbongowo/DEVOPS/actions/workflows/helm.yml/badge.svg)](https://github.com/mbongowo/DEVOPS/actions/workflows/helm.yml)
[![GitOps](https://github.com/mbongowo/DEVOPS/actions/workflows/gitops.yml/badge.svg)](https://github.com/mbongowo/DEVOPS/actions/workflows/gitops.yml)
[![Observability](https://github.com/mbongowo/DEVOPS/actions/workflows/observability.yml/badge.svg)](https://github.com/mbongowo/DEVOPS/actions/workflows/observability.yml)
[![Voting App](https://github.com/mbongowo/DEVOPS/actions/workflows/voting.yml/badge.svg)](https://github.com/mbongowo/DEVOPS/actions/workflows/voting.yml)
[![Ansible](https://github.com/mbongowo/DEVOPS/actions/workflows/ansible.yml/badge.svg)](https://github.com/mbongowo/DEVOPS/actions/workflows/ansible.yml)
[![Custom Action](https://github.com/mbongowo/DEVOPS/actions/workflows/custom-action.yml/badge.svg)](https://github.com/mbongowo/DEVOPS/actions/workflows/custom-action.yml)

| # | Project | What it demonstrates | CI |
|---|---------|----------------------|----|
| 1 | [`cicd-pipeline-petclinic`](./cicd-pipeline-petclinic) | Multi-stage Docker build of Spring PetClinic; GitHub Actions build/test → GHCR publish → gated production deploy | ![petclinic](../../actions/workflows/petclinic.yml/badge.svg) |
| 2 | [`terraform-azure-infra`](./terraform-azure-infra) | Modular, free-tier Azure infra (resource group, VNet/NSG, F1 Linux web app) with provider pinning and input validation | ![terraform](../../actions/workflows/terraform.yml/badge.svg) |
| 3 | [`k8s-online-boutique-helm`](./k8s-online-boutique-helm) | Data-driven Helm chart rendering 11 microservices + Redis from a single values map; hardened pods, gRPC/HTTP/TCP probes | ![helm](../../actions/workflows/helm.yml/badge.svg) |
| 4 | [`gitops-argocd`](./gitops-argocd) | Argo CD App-of-Apps, AppProject guardrails, and an ApplicationSet generating per-environment apps; kustomize overlays | ![gitops](../../actions/workflows/gitops.yml/badge.svg) |
| 5 | [`observability-stack`](./observability-stack) | Prometheus + Alertmanager + Grafana via docker-compose, with recording/alerting rules unit-tested by `promtool` | ![observability](../../actions/workflows/observability.yml/badge.svg) |
| 6 | [`docker-compose-voting-app`](./docker-compose-voting-app) | Five-service voting app (Flask/Redis/worker/Postgres/Node) orchestrated with Compose: healthchecks, `depends_on` conditions, dual networks, named volume, profiles; CI runs a live end-to-end smoke test | ![voting](../../actions/workflows/voting.yml/badge.svg) |
| 7 | [`ansible-server-provisioning`](./ansible-server-provisioning) | Idempotent server provisioning with Ansible roles (hardened base, Docker, nginx, ufw); tested with Molecule (converge + idempotence + verify) against a systemd container | ![ansible](../../actions/workflows/ansible.yml/badge.svg) |
| 8 | [`custom-github-action`](./custom-github-action) | Custom JavaScript GitHub Action (TypeScript + `ncc` bundle) that computes the next semantic version; Jest tests, a stale-bundle guard, and a CI job that runs the action on itself | ![custom-action](../../actions/workflows/custom-action.yml/badge.svg) |

These connect end-to-end: the Helm chart (3) deploys the Online Boutique app,
GitOps (4) reconciles that chart into the cluster across environments, and the
observability stack (5) monitors it.

## AWS cloud-native & DevSecOps wave

[![Three-Tier DevSecOps](https://github.com/mbongowo/DEVOPS/actions/workflows/devsecops-eks.yml/badge.svg)](https://github.com/mbongowo/DEVOPS/actions/workflows/devsecops-eks.yml)
[![Robot Shop Observability](https://github.com/mbongowo/DEVOPS/actions/workflows/robotshop.yml/badge.svg)](https://github.com/mbongowo/DEVOPS/actions/workflows/robotshop.yml)
[![Sock Shop GitOps](https://github.com/mbongowo/DEVOPS/actions/workflows/sockshop.yml/badge.svg)](https://github.com/mbongowo/DEVOPS/actions/workflows/sockshop.yml)
[![DevSecOps Pipeline](https://github.com/mbongowo/DEVOPS/actions/workflows/devsecops.yml/badge.svg)](https://github.com/mbongowo/DEVOPS/actions/workflows/devsecops.yml)
[![Flask CI/CD](https://github.com/mbongowo/DEVOPS/actions/workflows/flask.yml/badge.svg)](https://github.com/mbongowo/DEVOPS/actions/workflows/flask.yml)
[![AWS Platform](https://github.com/mbongowo/DEVOPS/actions/workflows/platform.yml/badge.svg)](https://github.com/mbongowo/DEVOPS/actions/workflows/platform.yml)
[![Supply-Chain Security](https://github.com/mbongowo/DEVOPS/actions/workflows/supply-chain.yml/badge.svg)](https://github.com/mbongowo/DEVOPS/actions/workflows/supply-chain.yml)

| # | Project | What it demonstrates | CI |
|---|---------|----------------------|----|
| 01 | [`01-three-tier-devsecops-eks`](./01-three-tier-devsecops-eks) | Flagship 3-tier app (React + Node/Express + MongoDB) for EKS: Terraform VPC/EKS/ECR, hardened Helm chart, Argo CD, and a CI pipeline with Trivy/Checkov gates | ![devsecops-eks](../../actions/workflows/devsecops-eks.yml/badge.svg) |
| 02 | [`02-robotshop-observability`](./02-robotshop-observability) | Observability layer over Stan's Robot Shop: `promtool`-tested SLO burn-rate alerts (multi-window), recording rules, golden-signal + SLO Grafana dashboards, Alertmanager routing, OTel/Tempo/Loki | ![robotshop](../../actions/workflows/robotshop.yml/badge.svg) |
| 03 | [`03-sockshop-gitops`](./03-sockshop-gitops) | Sock Shop delivered via GitOps: Kustomize base + dev/prod overlays, Argo CD ApplicationSet, and an Argo Rollouts canary with an analysis-driven auto-rollback | ![sockshop](../../actions/workflows/sockshop.yml/badge.svg) |
| 04 | [`04-devsecops-cicd-pipeline`](./04-devsecops-cicd-pipeline) | Shift-left security pipeline with hard gates: Semgrep (SAST), gitleaks (secrets), Trivy (deps/image/IaC), Checkov — with report artifacts | ![devsecops](../../actions/workflows/devsecops.yml/badge.svg) |
| 05 | [`05-flask-cicd-terraform`](./05-flask-cicd-terraform) | Flask URL-shortener with the full loop: pytest + Prometheus metrics, Helm chart, Terraform (kind provider), and a live kind deploy + smoke test in CI | ![flask](../../actions/workflows/flask.yml/badge.svg) |
| 06 | [`06-aws-platform-terraform-ansible`](./06-aws-platform-terraform-ansible) | Provision-then-configure: Terraform builds the AWS foundation (VPC, EC2 fleet, RDS Postgres); Ansible configures the fleet via a tag-based dynamic inventory | ![platform](../../actions/workflows/platform.yml/badge.svg) |
| 07 | [`07-supply-chain-security`](./07-supply-chain-security) | End-to-end supply chain: Syft SBOM → Grype scan → Cosign sign + SBOM attestation → verify (signed passes, unsigned rejected), with Kyverno admission policies | ![supply-chain](../../actions/workflows/supply-chain.yml/badge.svg) |

## Repository layout

```
.
├── .github/workflows/          one path-filtered workflow per project
│   ├── petclinic.yml · terraform.yml · helm.yml · gitops.yml
│   ├── observability.yml · voting.yml · ansible.yml · custom-action.yml
│   └── devsecops-eks.yml · robotshop.yml · sockshop.yml · devsecops.yml
│       · flask.yml · platform.yml · supply-chain.yml
│
├── cicd-pipeline-petclinic/    terraform-azure-infra/
├── k8s-online-boutique-helm/   gitops-argocd/
├── observability-stack/        docker-compose-voting-app/
├── ansible-server-provisioning/ custom-github-action/
│
├── 01-three-tier-devsecops-eks/    02-robotshop-observability/
├── 03-sockshop-gitops/             04-devsecops-cicd-pipeline/
├── 05-flask-cicd-terraform/        06-aws-platform-terraform-ansible/
└── 07-supply-chain-security/
```

Each workflow uses `paths:` filters and a `working-directory`, so a change to
one project only runs that project's pipeline.

## How CI is wired in a monorepo

GitHub Actions only executes workflows under the **repository-root**
`.github/workflows/`. Each project therefore has its workflow at the root,
scoped to its own directory with a `paths:` filter — editing the Terraform
project won't trigger the Helm pipeline, and vice versa.

## Local validation

Every project documents how to validate it locally in its own README, and the
same commands run in CI. A few representative checks:

| Project | Local check |
|---------|-------------|
| petclinic | `./mvnw verify` |
| terraform | `terraform fmt -check && terraform init -backend=false && terraform validate` |
| helm | `helm lint . && helm template ob . \| kubeconform -strict -` |
| gitops | `kustomize build <overlay> \| kubeconform -strict -` + Argo CRD validation |
| observability | `promtool check config/rules`, `promtool test rules`, `amtool check-config` |
| voting | `docker compose config -q` (+ `docker compose up --build` for a live smoke test) |
| ansible | `yamllint . && ansible-lint && ansible-playbook --syntax-check site.yml` (+ `molecule test`) |
| custom-action | `npm ci && npm run typecheck && npm test && npm run build` |
| 06 platform | `terraform validate` + `ansible-lint` + playbook `--syntax-check` |
| 07 supply-chain | `syft <img>` → `grype sbom:… --fail-on critical` + `kyverno test policy/tests` |

## Licensing

This repository is [MIT](./LICENSE) licensed, **except** the derivative
`cicd-pipeline-petclinic`, which retains the upstream Spring PetClinic
[Apache-2.0](./cicd-pipeline-petclinic/LICENSE.txt) license. Each project also
carries its own `LICENSE`.
