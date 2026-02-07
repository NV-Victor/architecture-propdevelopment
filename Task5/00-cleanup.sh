#!/usr/bin/env bash
set -euo pipefail

NS="task5"

echo "==> Удаляем NetworkPolicy (если есть)..."
kubectl -n "$NS" delete networkpolicy default-deny-ingress \
  allow-front-to-backend allow-backend-to-front \
  allow-admin-front-to-admin-back allow-admin-back-to-admin-front \
  --ignore-not-found || true

# На случай если файлы существуют рядом — удалим и по ним (не упадёт, если нет):
kubectl delete -f Task5/task5-default-deny.yaml --ignore-not-found 2>/dev/null || true
kubectl delete -f Task5/non-admin-api-allow.yaml --ignore-not-found 2>/dev/null || true

echo "==> Удаляем сервисы и поды (если namespace ещё жив)..."
kubectl -n "$NS" delete svc front-end-app back-end-api-app admin-front-end-app admin-back-end-api-app --ignore-not-found || true
kubectl -n "$NS" delete pod front-end-app back-end-api-app admin-front-end-app admin-back-end-api-app --ignore-not-found || true

echo "==> Удаляем namespace целиком (самый полный cleanup)..."
kubectl delete namespace "$NS" --ignore-not-found || true

echo
echo "✅ Cleanup Task5 завершён."
echo "Проверка:"
echo "  kubectl get ns $NS"

