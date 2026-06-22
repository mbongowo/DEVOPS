# k8s-online-boutique-helm

A Helm chart that deploys Google's [Online Boutique](https://github.com/GoogleCloudPlatform/microservices-demo)
(a 11-service gRPC microservices demo, plus Redis) to Kubernetes.

The point of this chart is the **templating design**: every service is one entry
in a `services` map in `values.yaml`, and a single generic `deployment.yaml` /
`service.yaml` ranges over that map. Adding, removing, or retuning a service is a
data change in `values.yaml` — the templates never change.

## Why this design

The upstream project ships ~1,500 lines of near-identical raw manifests (one
Deployment + Service per service, copy-pasted). This chart collapses that to two
generic templates driven by data, which means:

- consistent labels, security context, probes, and resources everywhere;
- per-service overrides only where a service genuinely differs (image, port,
  probe type, resources, writable root filesystem);
- environment-specific behaviour via overlay values files.

## What it renders

`helm template` produces **25 resources** with the default values:

| Kind            | Count | Notes                                            |
| --------------- | ----- | ------------------------------------------------ |
| Deployment      | 12    | 11 microservices + `redis-cart`                  |
| Service         | 11    | ClusterIP, one per service with an inbound port  |
| Service (LB)    | 1     | `frontend-external` (LoadBalancer)               |
| ServiceAccount  | 1     | shared, `automountServiceAccountToken: false`    |

`loadgenerator` has no inbound port, so it gets a Deployment but no Service.

## Hardening defaults

Every container runs with:

- `runAsNonRoot`, `runAsUser: 1000`, `allowPrivilegeEscalation: false`
- all Linux capabilities dropped
- `readOnlyRootFilesystem: true` (with an `emptyDir` mounted at `/tmp`)

Services that need a writable root filesystem (`loadgenerator`, `redis-cart`)
opt out per-service via `readOnlyRootFilesystem: false`.

## Probes

Probe type is declared per service and the template renders the right kind:

- `grpc` — native gRPC health checks (the gRPC services)
- `http` — `httpGet` with optional headers (the frontend's `/_healthz`)
- `tcp` — `tcpSocket` (Redis)
- `none` — no probe (the load generator)

## Usage

Validate locally without a cluster:

```bash
helm lint .
helm template ob . | kubeconform -strict -summary -kubernetes-version 1.30.0 -
```

Install into a cluster:

```bash
# Production-ish: frontend behind a cloud LoadBalancer
helm install ob . -n boutique --create-namespace

# Local cluster (kind/minikube): ClusterIP frontend, no load generator
helm install ob . -n boutique --create-namespace -f values-dev.yaml
kubectl port-forward -n boutique svc/frontend 80:80
# open http://localhost:80
```

Uninstall:

```bash
helm uninstall ob -n boutique
```

## Configuration

Key values in [`values.yaml`](./values.yaml):

| Path                          | Description                                           |
| ----------------------------- | ----------------------------------------------------- |
| `image.repository` / `.tag`   | Base image registry and tag for first-party services  |
| `services.<name>.port`        | Container port (also the Service `targetPort`)         |
| `services.<name>.servicePort` | Service port if it differs from the container port     |
| `services.<name>.env`         | Map of environment variables                           |
| `services.<name>.probe.type`  | `grpc` \| `http` \| `tcp` \| `none`                    |
| `services.<name>.resources`   | Per-service resources (else `defaultResources`)        |
| `services.<name>.external`    | Render an extra external Service (frontend)            |
| `services.<name>.enabled`     | Set `false` to skip a service entirely                 |

[`values-dev.yaml`](./values-dev.yaml) is a thin overlay for local clusters
(ClusterIP frontend, load generator disabled).

## CI

[`.github/workflows/helm.yml`](.github/workflows/helm.yml):

1. `helm lint`, then render both value sets and schema-validate every manifest
   with `kubeconform` (offline, no cluster).
2. Spin up a `kind` cluster and run `helm install --dry-run=server` to confirm
   the chart is installable against a real API server.

## Credits & license

Application images and the demo itself are by Google Cloud Platform's
[microservices-demo](https://github.com/GoogleCloudPlatform/microservices-demo)
(Apache-2.0). This Helm chart is original work, licensed [MIT](./LICENSE).
