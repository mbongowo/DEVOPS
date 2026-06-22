# gitops-argocd

Declarative GitOps configuration for [Argo CD](https://argo-cd.readthedocs.io/)
using the **App-of-Apps** pattern and an **ApplicationSet**. This repo is the
single source of truth for what runs in the cluster — Argo CD reconciles the
live state to match what's committed here.

It deploys the [Online Boutique Helm chart](https://github.com/mbongowo/k8s-online-boutique-helm)
(built earlier in this portfolio) plus a kustomize-managed platform config.

## Layout

```
.
├── bootstrap/
│   └── root.yaml            App-of-Apps root — the only thing you apply by hand
├── projects/
│   └── boutique-project.yaml AppProject: allow-lists source repos + destinations
├── apps/
│   ├── online-boutique.yaml  Application → Helm chart repo
│   └── platform-config.yaml  Application → kustomize overlay (this repo)
├── appsets/
│   └── boutique-environments.yaml  ApplicationSet → one app per environment
└── manifests/
    └── platform-config/      kustomize base + dev/prod overlays
        ├── base/
        └── overlays/{dev,prod}/
```

## How it fits together

```
root (App-of-Apps)
  └── recurses projects/, apps/, appsets/
        ├── AppProject "boutique"           (guardrails)
        ├── Application online-boutique      → Helm chart → ns boutique
        ├── Application platform-config       → kustomize overlay → ns platform-dev
        └── ApplicationSet boutique-environments
              ├── boutique-dev   → Helm (values-dev.yaml)  → ns boutique-dev
              └── boutique-prod  → Helm (values.yaml)      → ns boutique-prod
```

- **App-of-Apps** (`bootstrap/root.yaml`) — apply this one manifest and Argo CD
  pulls in everything else. `directory.recurse` with an `include` glob picks up
  `projects/`, `apps/` and `appsets/`.
- **AppProject** (`projects/boutique-project.yaml`) — restricts which repos may
  be deployed and into which namespaces, and limits cluster-scoped resources to
  `Namespace`. Guardrails, committed as code.
- **ApplicationSet** (`appsets/boutique-environments.yaml`) — a list generator
  renders one `Application` per environment from a single template. Adding an
  environment is one list entry.

## Bootstrap

With an Argo CD instance already running in the `argocd` namespace:

```bash
kubectl apply -f bootstrap/root.yaml
```

That's it — Argo CD takes over and syncs the rest.

## Validate locally

No cluster required:

```bash
# Core resources from the kustomize overlays
kustomize build manifests/platform-config/overlays/dev \
  | kubeconform -strict -summary -kubernetes-version 1.30.0 -

# Argo CD CRDs, validated against the community CRD schema catalog
kubeconform -strict -summary \
  -schema-location default \
  -schema-location 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json' \
  bootstrap projects apps appsets
```

## CI

[`.github/workflows/gitops.yml`](.github/workflows/gitops.yml) runs on every
push and PR: it `kustomize build`s each overlay and schema-validates the output,
then validates all Argo CD `Application`/`ApplicationSet`/`AppProject` manifests
against the [datreeio CRD catalog](https://github.com/datreeio/CRDs-catalog).
Fully offline of any cluster.

## License

[MIT](./LICENSE). Argo CD is a CNCF project; the Online Boutique application is
by Google Cloud Platform.
