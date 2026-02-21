#!/usr/bin/env bash
set -euo pipefail
kubectl apply -f 05-bind-users.yaml
kubectl get clusterrolebinding devops-user-cluster-admin security-user-auditor
kubectl -n sales get rolebinding sales-admin-domain-admin analyst-user-readonly