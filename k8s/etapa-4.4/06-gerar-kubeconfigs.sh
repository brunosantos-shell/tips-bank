#!/usr/bin/env bash

set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

KEY_DIR="${BASE_DIR}/evidencias/chaves"
CERT_DIR="${BASE_DIR}/evidencias/certificados"
KUBECONFIG_DIR="${BASE_DIR}/evidencias/kubeconfigs"

mkdir -p "${KUBECONFIG_DIR}"

CURRENT_CONTEXT="$(kubectl config current-context)"

CLUSTER_NAME="$(
  kubectl config view \
    --minify \
    -o jsonpath='{.contexts[0].context.cluster}'
)"

SERVER="$(
  kubectl config view \
    --minify \
    -o jsonpath='{.clusters[0].cluster.server}'
)"

CA_DATA="$(
  kubectl config view \
    --raw \
    --minify \
    -o jsonpath='{.clusters[0].cluster.certificate-authority-data}'
)"

if [[ -z "${CA_DATA}" ]]; then
  CA_FILE="$(
    kubectl config view \
      --raw \
      --minify \
      -o jsonpath='{.clusters[0].cluster.certificate-authority}'
  )"

  if [[ -z "${CA_FILE}" || ! -f "${CA_FILE}" ]]; then
    echo "ERRO: não foi possível localizar a CA do cluster."
    exit 1
  fi

  CA_DATA="$(
    base64 < "${CA_FILE}" |
    tr -d '\n'
  )"
fi

create_kubeconfig() {
  local username="$1"
  local output_name="$2"
  local default_namespace="$3"

  local cert_file="${CERT_DIR}/${username}.crt"
  local key_file="${KEY_DIR}/${username}.key"
  local output_file="${KUBECONFIG_DIR}/${output_name}"

  if [[ ! -f "${cert_file}" ]]; then
    echo "ERRO: certificado não encontrado: ${cert_file}"
    exit 1
  fi

  if [[ ! -f "${key_file}" ]]; then
    echo "ERRO: chave não encontrada: ${key_file}"
    exit 1
  fi

  cat > "${output_file}" <<EOF
apiVersion: v1
kind: Config
clusters:
  - name: ${CLUSTER_NAME}
    cluster:
      server: ${SERVER}
      certificate-authority-data: ${CA_DATA}
users:
  - name: ${username}
    user:
      client-certificate: ../certificados/${username}.crt
      client-key: ../chaves/${username}.key
contexts:
  - name: ${username}@${CLUSTER_NAME}
    context:
      cluster: ${CLUSTER_NAME}
      user: ${username}
      namespace: ${default_namespace}
current-context: ${username}@${CLUSTER_NAME}
EOF

  chmod 600 "${output_file}"

  echo "Kubeconfig criado: ${output_file}"
}

create_kubeconfig \
  "operador-contas" \
  "op-contas.kubeconfig" \
  "tipsbank-contas"

create_kubeconfig \
  "operador-transacoes" \
  "op-transacoes.kubeconfig" \
  "tipsbank-transacoes"

create_kubeconfig \
  "auditor-global" \
  "auditor.kubeconfig" \
  "default"

create_kubeconfig \
  "sre" \
  "sre.kubeconfig" \
  "default"

echo
echo "Kubeconfigs gerados:"
ls -l "${KUBECONFIG_DIR}"