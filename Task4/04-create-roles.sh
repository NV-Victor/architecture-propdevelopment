#!/usr/bin/env bash
set -euo pipefail
kubectl apply -f 04-create-roles.yaml
kubectl get clusterrole developer-readonly domain-admin security-auditor