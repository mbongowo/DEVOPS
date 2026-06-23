#!/usr/bin/env bash
# Local end-to-end: build the image, spin up a kind cluster, deploy via Helm.
set -euo pipefail
cd "$(dirname "$0")/.."

CLUSTER="${CLUSTER:-flask-cicd}"
IMAGE="flask-urlshortener:dev"

echo ">> building image"
docker build -t "$IMAGE" app

if ! kind get clusters | grep -qx "$CLUSTER"; then
  echo ">> creating kind cluster $CLUSTER"
  kind create cluster --name "$CLUSTER" --image kindest/node:v1.31.2
fi

echo ">> loading image into kind"
kind load docker-image "$IMAGE" --name "$CLUSTER"

echo ">> helm upgrade --install"
helm upgrade --install us chart \
  --set image.repository=flask-urlshortener --set image.tag=dev \
  --set ingress.enabled=false --wait --timeout 150s

echo ">> port-forward on http://localhost:8000"
echo "   kubectl port-forward svc/us-urlshortener 8000:80"
