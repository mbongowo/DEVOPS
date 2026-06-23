# DEVOPS

A monorepo of hands-on DevOps projects, each self-contained in its own
directory and validated by its own CI pipeline. Together they walk an
application from source to a monitored, GitOps-managed deployment.

### Pipelines

[![petclinic](https://github.com/mbongowo/DEVOPS/actions/workflows/petclinic.yml/badge.svg)](https://github.com/mbongowo/DEVOPS/actions/workflows/petclinic.yml)
[![Terraform](https://github.com/mbongowo/DEVOPS/actions/workflows/terraform.yml/badge.svg)](https://github.com/mbongowo/DEVOPS/actions/workflows/terraform.yml)
[![Helm](https://github.com/mbongowo/DEVOPS/actions/workflows/helm.yml/badge.svg)](https://github.com/mbongowo/DEVOPS/actions/workflows/helm.yml)
[![GitOps](https://github.com/mbongowo/DEVOPS/actions/workflows/gitops.yml/badge.svg)](https://github.com/mbongowo/DEVOPS/actions/workflows/gitops.yml)
[![Observability](https://github.com/mbongowo/DEVOPS/actions/workflows/observability.yml/badge.svg)](https://github.com/mbongowo/DEVOPS/actions/workflows/observability.yml)
[![Voting App](https://github.com/mbongowo/DEVOPS/actions/workflows/voting.yml/badge.svg)](https://github.com/mbongowo/DEVOPS/actions/workflows/voting.yml)
[![Ansible](https://github.com/mbongowo/DEVOPS/actions/workflows/ansible.yml/badge.svg)](https://github.com/mbongowo/DEVOPS/actions/workflows/ansible.yml)
[![Custom Action](https://github.com/mbongowo/DEVOPS/actions/workflows/custom-action.yml/badge.svg)](https://github.com/mbongowo/DEVOPS/actions/workflows/custom-action.yml)

All eight project pipelines build and validate independently on every push.

## Projects

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

They also connect end-to-end: the Helm chart (3) deploys the Online Boutique
app, GitOps (4) reconciles that chart into the cluster across environments, and
the observability stack (5) monitors it.

## Repository layout

```
.
├── .github/workflows/      one workflow per project, path-filtered
│   ├── petclinic.yml        triggers on cicd-pipeline-petclinic/**
│   ├── terraform.yml        triggers on terraform-azure-infra/**
│   ├── helm.yml             triggers on k8s-online-boutique-helm/**
│   ├── gitops.yml           triggers on gitops-argocd/**
│   ├── observability.yml    triggers on observability-stack/**
│   ├── voting.yml           triggers on docker-compose-voting-app/**
│   ├── ansible.yml          triggers on ansible-server-provisioning/**
│   └── custom-action.yml    triggers on custom-github-action/**
├── cicd-pipeline-petclinic/
├── terraform-azure-infra/
├── k8s-online-boutique-helm/
├── gitops-argocd/
├── observability-stack/
├── docker-compose-voting-app/
├── ansible-server-provisioning/
└── custom-github-action/
```

Each workflow uses `paths:` filters and a `working-directory`, so a change to
one project only runs that project's pipeline.

## How CI is wired in a monorepo

GitHub Actions only executes workflows under the **repository-root**
`.github/workflows/`. Each project therefore has its workflow at the root,
scoped to its own directory with a `paths:` filter — editing the Terraform
project won't trigger the Helm pipeline, and vice versa.

## Local validation

Every project documents how to validate it locally in its own README. The same
commands run in CI. In short:

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

## Licensing

This repository is [MIT](./LICENSE) licensed, **except** the derivative
`cicd-pipeline-petclinic`, which retains the upstream Spring PetClinic
[Apache-2.0](./cicd-pipeline-petclinic/LICENSE.txt) license. Each project also
carries its own `LICENSE`.
