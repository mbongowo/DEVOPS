# Incident postmortem — Cart 5xx spike & error-budget burn

**Status:** Resolved · **Severity:** SEV-2 · **Duration:** 18 min
**Services:** `cart` (Node.js) → `mongodb`
**SLO impacted:** Availability (99.9% target) and p99 latency (<1s)

> This is a **deliberately injected fault** used to exercise the observability
> stack end-to-end: detection → alerting → diagnosis → resolution. The alerts
> referenced below are unit-tested in
> [`monitoring/prometheus/tests/slo_tests.yml`](../monitoring/prometheus/tests/slo_tests.yml).

## Summary

A fault injected into the `cart` service (MongoDB connection pool exhausted via a
`tc netem` delay on the `mongodb` pod) caused ~10% of `/api/cart/*` requests to
return `500` and pushed p99 latency above 1s. The 99.9% availability error budget
burned at ~100× the sustainable rate. Detection to mitigation was 6 minutes.

## How it was injected (reproduce)

```bash
# add 800ms latency + 5% loss to mongodb to starve the cart connection pool
kubectl -n robot-shop exec deploy/mongodb -- \
  tc qdisc add dev eth0 root netem delay 800ms loss 5%
# drive traffic
k6 run -e BASE_URL=http://localhost:8080 load/k6-loadtest.js
```

## Timeline (UTC)

| Time | Event |
|------|-------|
| 14:02 | Fault injected on `mongodb`; k6 browse/cart load running |
| 14:04 | `cart` 5xx ratio crosses 5%; **HighErrorRate** enters _pending_ |
| 14:06 | **ErrorBudgetBurnFast** fires (1h **and** 5m windows >14.4×) → Slack `#robotshop-pager` |
| 14:07 | **HighLatencyP99** fires (p99 ≈ 2.4s) |
| 14:08 | On-call opens **Golden Signals** dashboard, isolates spike to `cart`; traces in Tempo show time spent in the `mongodb` span |
| 14:14 | `tc` qdisc removed; 5xx ratio recovers below 1% |
| 14:18 | Alerts resolve; error budget consumption stops |

## Detection

The path that caught it (all committed as code):

- **Metrics:** `service:http_error_ratio:rate5m` recording rule + the
  multi-window **ErrorBudgetBurnFast** burn-rate alert (Google SRE 14.4× fast-burn).
- **Traces:** OTLP traces → Tempo; the `cart → mongodb` span latency made the root
  cause obvious.
- **Logs:** `cart` pod logs in Loki showed `MongoTimeoutError` correlated by time.

## Root cause

Latency on `mongodb` exhausted the `cart` service's connection pool; requests
queued past the client timeout and surfaced as `500`s. The single MongoDB replica
had no read fallback.

## What went well / what didn't

- 👍 Burn-rate alert fired fast and only once (warning inhibited by the critical).
- 👎 No dashboard tied cart errors directly to MongoDB saturation — added a Mongo
  panel to the Golden Signals board.

## Action items

1. Add a MongoDB saturation panel + `mongodb` connection-pool ServiceMonitor.
2. Set a client-side timeout + retry budget on the `cart` → `mongodb` driver.
3. Add a slow-burn (6×, 6h/30m) companion alert for gradual degradation.
