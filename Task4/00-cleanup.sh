#!/usr/bin/env bash
set -euo pipefail

echo "==> Удаляем RBAC (roles/bindings)..."
kubectl delete -f 05-bind-users.yaml --ignore-not-found || true
kubectl delete -f 04-create-roles.yaml --ignore-not-found || true

kubectl delete clusterrole developer-readonly domain-admin security-auditor --ignore-not-found || true
kubectl delete clusterrolebinding devops-user-cluster-admin security-user-auditor --ignore-not-found || true
kubectl delete rolebinding sales-admin-domain-admin analyst-user-readonly -n sales --ignore-not-found || true

echo "==> Удаляем пользователей и контексты из kubeconfig..."
for ctx in devops-user-ctx sales-admin-ctx analyst-user-ctx security-user-ctx; do
  kubectl config delete-context "$ctx" >/dev/null 2>&1 || true
done

for usr in devops-user sales-admin analyst-user security-user; do
  kubectl config delete-user "$usr" >/dev/null 2>&1 || true
done

echo "==>  Удаляем неймспейсы доменов (sales/housing/finance/data)"

 kubectl delete namespace sales housing finance data --ignore-not-found || true

echo "==> Удаляем локальные сертификаты (pki/)?"

 rm -rf ./pki


echo
echo "Cleanup завершён."
echo "Проверка:"
echo "  kubectl config get-contexts"
kubectl config get-contexts
echo "  kubectl get clusterrole developer-readonly domain-admin security-auditor cluster-admin"
kubectl get clusterrole developer-readonly domain-admin security-auditor cluster-admin

