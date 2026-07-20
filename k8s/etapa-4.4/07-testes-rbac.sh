#!/usr/bin/env bash

set -u

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KCFG_DIR="${BASE_DIR}/evidencias/kubeconfigs"
EVIDENCE_FILE="${BASE_DIR}/evidencias/EVIDENCIAS-RBAC.md"

OP_CONTAS="${KCFG_DIR}/op-contas.kubeconfig"
OP_TRANSACOES="${KCFG_DIR}/op-transacoes.kubeconfig"
AUDITOR="${KCFG_DIR}/auditor.kubeconfig"
SRE="${KCFG_DIR}/sre.kubeconfig"

POD_CONTAS="$(
  kubectl get pods \
    -n tipsbank-contas \
    -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true
)"

{
  echo "# Etapa 4.4 — RBAC com certificados X.509"
  echo

  echo "## CSRs"
  echo '```text'
  kubectl get csr
  echo '```'
  echo

  echo "## Roles e RoleBindings"
  echo '```text'
  kubectl get role,rolebinding \
    -n tipsbank-contas

  kubectl get role,rolebinding \
    -n tipsbank-transacoes
  echo '```'
  echo

  echo "## ClusterRoles e ClusterRoleBindings"
  echo '```text'
  kubectl get clusterrole auditor-global
  kubectl get clusterrolebinding auditor-global sre-cluster-admin
  echo '```'
  echo

  echo "## ServiceAccounts"
  echo '```text'
  kubectl get serviceaccount sa-api-contas \
    -n tipsbank-contas

  kubectl get serviceaccount sa-api-transacoes \
    -n tipsbank-transacoes
  echo '```'
  echo

  echo "## Operador contas — acesso permitido"
  echo '```text'
  kubectl \
    --kubeconfig="${OP_CONTAS}" \
    get pods \
    -n tipsbank-contas 2>&1
  echo '```'
  echo

  echo "## Operador contas — acesso negado"
  echo '```text'
  kubectl \
    --kubeconfig="${OP_CONTAS}" \
    get pods \
    -n tipsbank-transacoes 2>&1 || true
  echo '```'
  echo

  echo "## Auditor — acesso global permitido"
  echo '```text'
  kubectl \
    --kubeconfig="${AUDITOR}" \
    get pods \
    -A 2>&1
  echo '```'
  echo

  echo "## Auditor — exclusão negada"
  echo '```text'

  if [[ -n "${POD_CONTAS}" ]]; then
    kubectl \
      --kubeconfig="${AUDITOR}" \
      delete pod "${POD_CONTAS}" \
      -n tipsbank-contas 2>&1 || true
  else
    echo "Nenhum Pod encontrado em tipsbank-contas."
  fi

  echo '```'
  echo

  echo "## Operador transações — exec permitido"
  echo '```text'
  kubectl \
    --kubeconfig="${OP_TRANSACOES}" \
    auth can-i create pods/exec \
    -n tipsbank-transacoes 2>&1
  echo '```'
  echo

  echo "## SRE — cluster-admin"
  echo '```text'
  kubectl \
    --kubeconfig="${SRE}" \
    auth can-i '*' '*' \
    --all-namespaces 2>&1
  echo '```'

} | tee "${EVIDENCE_FILE}"

echo
echo "Evidência criada em:"
echo "${EVIDENCE_FILE}"