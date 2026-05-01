#!/usr/bin/env bash
set -euo pipefail

REGISTRY_SERVER="${REGISTRY_SERVER:-ghcr.io}"
REGISTRY_USER="${REGISTRY_USER:-SEU_USUARIO}"
REGISTRY_TOKEN="${REGISTRY_TOKEN:-SEU_TOKEN}"
REGISTRY_EMAIL="${REGISTRY_EMAIL:-seu-email@dominio.com}"

for NS in tipsbank-contas tipsbank-transacoes tipsbank-auditoria tipsbank-web; do
  kubectl create secret docker-registry registry-secret \
    --docker-server="$REGISTRY_SERVER" \
    --docker-username="$REGISTRY_USER" \
    --docker-password="$REGISTRY_TOKEN" \
    --docker-email="$REGISTRY_EMAIL" \
    -n "$NS" \
    --dry-run=client -o yaml | kubectl apply -f -
done
