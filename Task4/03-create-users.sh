#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="./pki"
mkdir -p "$OUT_DIR"

CA_CERT="${HOME}/.minikube/ca.crt"
CA_KEY="${HOME}/.minikube/ca.key"

if [[ ! -f "$CA_CERT" || ! -f "$CA_KEY" ]]; then
  echo "Не найдены CA-файлы minikube: $CA_CERT или $CA_KEY"
  echo "Проверь, что minikube запущен."
  exit 1
fi

CLUSTER_NAME="$(kubectl config view --minify -o jsonpath='{.clusters[0].name}')"
echo "Используем кластер kubeconfig: ${CLUSTER_NAME}"
echo "PKI будет сохранён в: ${OUT_DIR}"
echo

# Формат строк: user;group;namespace
USERS=(
  "devops-user;platform-admins;default"
  "sales-admin;sales-admins;sales"
  "analyst-user;readers;default"
  "security-user;security-auditors;default"
)

for ENTRY in "${USERS[@]}"; do
  IFS=';' read -r USER GROUP NS <<< "$ENTRY"

  KEY="${OUT_DIR}/${USER}.key"
  CSR="${OUT_DIR}/${USER}.csr"
  CRT="${OUT_DIR}/${USER}.crt"

  if [[ ! -f "$KEY" ]]; then
    openssl genrsa -out "$KEY" 2048 >/dev/null 2>&1
    echo "Создан ключ: $KEY"
  else
    echo "Ключ уже существует: $KEY"
  fi

  openssl req -new -key "$KEY" -out "$CSR" -subj "/CN=${USER}/O=${GROUP}" >/dev/null 2>&1
  echo "Создан CSR: $CSR (CN=${USER}, O=${GROUP})"

  openssl x509 -req -in "$CSR" -CA "$CA_CERT" -CAkey "$CA_KEY" -CAcreateserial \
    -out "$CRT" -days 365 -sha256 >/dev/null 2>&1
  echo "Подписан сертификат: $CRT"

  kubectl config set-credentials "${USER}" \
    --client-certificate="$CRT" \
    --client-key="$KEY" \
    --embed-certs=true >/dev/null

  CONTEXT="${USER}-ctx"
  kubectl config set-context "$CONTEXT" \
    --cluster="$CLUSTER_NAME" \
    --user="$USER" \
    --namespace="$NS" >/dev/null

  echo "Добавлен kubeconfig context: ${CONTEXT} (namespace=${NS})"
  echo
done

echo "Готово. Список контекстов:"
kubectl config get-contexts
