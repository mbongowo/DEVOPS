# observability-stack

A self-contained **Prometheus + Alertmanager + Grafana** monitoring stack, with
node-exporter and cAdvisor for host/container metrics. Runs with one
`docker compose up`, and every config is validated in CI — including
**promtool unit tests** for the alerting rules.

Themed around the [Online Boutique](https://github.com/mbongowo/k8s-online-boutique-helm)
app from elsewhere in this portfolio.

## Stack

| Component      | Port | Purpose                                  |
| -------------- | ---- | ---------------------------------------- |
| Prometheus     | 9090 | Scraping, recording rules, alerting      |
| Alertmanager   | 9093 | Alert routing, grouping, inhibition      |
| Grafana        | 3000 | Dashboards (provisioned datasource + JSON) |
| node-exporter  | 9100 | Host metrics                             |
| cAdvisor       | 8080 | Container metrics                        |

## Layout

```
.
├── docker-compose.yml
├── prometheus/
│   ├── prometheus.yml          scrape configs + alerting + rule_files
│   ├── rules/
│   │   ├── alerts.yml          alerting rules (4)
│   │   └── recording.yml       recording rules (2)
│   └── tests/
│       └── rules_test.yml      promtool unit tests
├── alertmanager/
│   └── alertmanager.yml        routing tree, inhibition, receivers
└── grafana/
    └── provisioning/
        ├── datasources/        Prometheus datasource
        └── dashboards/         provider + Online Boutique dashboard
```

## Run it

```bash
docker compose up -d
```

- Grafana: http://localhost:3000 (admin / admin) — the Prometheus datasource and
  the "Online Boutique — Service Overview" dashboard are auto-provisioned.
- Prometheus: http://localhost:9090 (try the `/alerts` and `/rules` pages).
- Alertmanager: http://localhost:9093

```bash
docker compose down            # stop
docker compose down -v         # stop and wipe volumes
```

## Rules

**Alerting** (`prometheus/rules/alerts.yml`): `TargetDown`, `HighErrorRate`,
`HighNodeMemory`, `HighNodeCPU`.

**Recording** (`prometheus/rules/recording.yml`): `job:http_requests:rate5m`
and `job:http_request_errors:ratio_rate5m` (the latter backs the error-rate
alert and the Grafana panel).

### Unit tests

The rules are unit-tested with `promtool`, so a refactor that breaks an alert
fails CI:

```bash
promtool test rules prometheus/tests/rules_test.yml
```

The tests assert that `TargetDown` fires after 2 minutes down (and stays quiet
when the target is up) and that a 10% 5xx rate fires `HighErrorRate` with the
correct `"10%"` annotation.

## Validate everything locally

```bash
( cd prometheus && promtool check config prometheus.yml )
promtool check rules prometheus/rules/*.yml
promtool test rules prometheus/tests/rules_test.yml
amtool check-config alertmanager/alertmanager.yml
docker compose config -q
```

## CI

[`.github/workflows/observability.yml`](.github/workflows/observability.yml)
runs all of the above on every push and PR: `promtool` config/rules/tests,
`amtool check-config`, JSON validation of every Grafana dashboard, and
`docker compose config`.

## License

[MIT](./LICENSE).
