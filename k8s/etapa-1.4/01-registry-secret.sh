#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="$(dirname "$0")/registry.env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Arquivo $ENV_FILE não encontrado."
  exit 1
fi

set -a
source "$ENV_FILE"
set +a

: "${REGISTRY_SERVER:?REGISTRY_SERVER não definido}"
: "${REGISTRY_USER:?REGISTRY_USER não definido}"
: "${REGISTRY_TOKEN:?REGISTRY_TOKEN não definido}"
: "${REGISTRY_EMAIL:?REGISTRY_EMAIL não definido}"

NAMESPACES=(
  tipsbank-contas
  tipsbank-transacoes
  tipsbank-auditoria
  tipsbank-web
)

echo "[+] Criando namespaces..."

for NS in "${NAMESPACES[@]}"; do
  kubectl create namespace "$NS" \
    --dry-run=client -o yaml | kubectl apply -f -
done

echo "[+] Criando registry-secret..."

for NS in "${NAMESPACES[@]}"; do
  kubectl create secret docker-registry registry-secret \
    --docker-server="$REGISTRY_SERVER" \
    --docker-username="$REGISTRY_USER" \
    --docker-password="$REGISTRY_TOKEN" \
    --docker-email="$REGISTRY_EMAIL" \
    -n "$NS" \
    --dry-run=client -o yaml | kubectl apply -f -
done

echo "[+] Finalizado com sucesso."
