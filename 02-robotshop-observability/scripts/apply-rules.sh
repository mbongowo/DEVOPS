#!/usr/bin/env bash
# Wrap the promtool-tested plain rule files into a single PrometheusRule CRD and
# apply it — the rule files stay the single source of truth (no duplication).
set -euo pipefail
cd "$(dirname "$0")/.."
NS="${NS:-monitoring}"

python3 - "$NS" monitoring/prometheus/rules/*.yml <<'PY' | kubectl apply -n "$NS" -f -
import sys, yaml
ns = sys.argv[1]
groups = []
for path in sys.argv[2:]:
    with open(path) as fh:
        groups += yaml.safe_load(fh).get("groups", [])
crd = {
    "apiVersion": "monitoring.coreos.com/v1",
    "kind": "PrometheusRule",
    "metadata": {"name": "robotshop-slo", "labels": {"release": "kps"}},
    "spec": {"groups": groups},
}
print(yaml.safe_dump(crd, sort_keys=False))
PY
echo "applied PrometheusRule robotshop-slo to namespace $NS"
