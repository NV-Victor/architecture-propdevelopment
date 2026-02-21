#!/usr/bin/env bash
set -u

echo "===== Проверка RBAC ====="
echo

run_can_i () {
  local label="$1"; shift
  echo -n "$label: "

  out="$("$@" 2>&1 || true)"

  # Убираем warning-строки
  filtered="$(echo "$out" | sed '/^Warning:/d' | tr -d '\r')"

  # Берём последнее yes/no из вывода
  answer="$(echo "$filtered" | awk '
    { for (i=1; i<=NF; i++) if ($i=="yes" || $i=="no") last=$i }
    END { print last }
  ')"

  if [[ "$answer" == "yes" || "$answer" == "no" ]]; then
    echo "$answer"
  else
    echo "ERROR"
    echo "----- output -----"
    echo "$out"
    echo "------------------"
  fi
  return 0
}


run_cmd () {
  local title="$1"; shift
  echo "$title"
  "$@" 2>&1 | head -n 20
  echo
  return 0
}

echo "===== Проверка прав доступа (RBAC) ====="
echo

echo "== Analyst (доступ только на чтение в namespace sales) =="
run_can_i "Просмотр pod в sales" kubectl --context=analyst-user-ctx auth can-i list pods -n sales
run_can_i "Создание deployment в sales" kubectl --context=analyst-user-ctx auth can-i create deployment -n sales
run_can_i "Просмотр namespace (уровень кластера)" kubectl --context=analyst-user-ctx auth can-i list namespaces
echo

echo "== Sales admin (управление только namespace sales) =="
run_can_i "Создание deployment в sales" kubectl --context=sales-admin-ctx auth can-i create deployment -n sales
run_can_i "Удаление service в sales" kubectl --context=sales-admin-ctx auth can-i delete service -n sales
run_can_i "Создание deployment в finance" kubectl --context=sales-admin-ctx auth can-i create deployment -n finance
run_can_i "Доступ к secrets в sales" kubectl --context=sales-admin-ctx auth can-i get secrets -n sales
echo

echo "== Security auditor (аудит, чтение secrets на уровне кластера) =="
run_can_i "Просмотр всех secrets в кластере" kubectl --context=security-user-ctx auth can-i list secrets -A
run_can_i "Чтение secrets в kube-system" kubectl --context=security-user-ctx auth can-i get secrets -n kube-system
run_can_i "Удаление secrets в kube-system" kubectl --context=security-user-ctx auth can-i delete secrets -n kube-system
echo

echo "== DevOps (полный административный доступ) =="
run_can_i "Полный доступ ко всем ресурсам (* * -A)" kubectl --context=devops-user-ctx auth can-i '*' '*' -A
echo

echo "===== Дополнительные проверки ====="
run_cmd "Analyst: список pod в sales" kubectl --context=analyst-user-ctx -n sales get pods
run_cmd "Security: список secrets в kube-system" kubectl --context=security-user-ctx -n kube-system get secrets

echo "===== Проверка завершена ====="