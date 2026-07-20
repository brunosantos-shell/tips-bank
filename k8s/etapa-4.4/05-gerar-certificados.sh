#!/usr/bin/env bash

set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KEY_DIR="${BASE_DIR}/evidencias/chaves"
CSR_DIR="${BASE_DIR}/evidencias/csrs"
CERT_DIR="${BASE_DIR}/evidencias/certificados"

USERS=(
  "operador-contas"
  "operador-transacoes"
  "auditor-global"
  "sre"
)

mkdir -p "${KEY_DIR}" "${CSR_DIR}" "${CERT_DIR}"

command -v kubectl >/dev/null 2>&1 || {
  echo "ERRO: kubectl não encontrado."
  exit 1
}

command -v openssl >/dev/null 2>&1 || {
  echo "ERRO: openssl não encontrado."
  exit 1
}

for USERNAME in "${USERS[@]}"; do
  echo
  echo "=================================================="
  echo "Gerando certificado para: ${USERNAME}"
  echo "=================================================="

  KEY_FILE="${KEY_DIR}/${USERNAME}.key"
  CSR_FILE="${CSR_DIR}/${USERNAME}.csr"
  CSR_YAML="${CSR_DIR}/${USERNAME}-csr.yaml"
  CERT_FILE="${CERT_DIR}/${USERNAME}.crt"

  if [[ ! -f "${KEY_FILE}" ]]; then
    openssl genrsa \
      -out "${KEY_FILE}" \
      3072
  else
    echo "Chave já existente: ${KEY_FILE}"
  fi

  chmod 600 "${KEY_FILE}"

  openssl req \
    -new \
    -key "${KEY_FILE}" \
    -out "${CSR_FILE}" \
    -subj "/CN=${USERNAME}/O=tipsbank-users"

  CSR_BASE64="$(
    base64 < "${CSR_FILE}" |
    tr -d '\n'
  )"

  cat > "${CSR_YAML}" <<EOF
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: ${USERNAME}
spec:
  request: ${CSR_BASE64}
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 31536000
  usages:
    - client auth
EOF

  if kubectl get csr "${USERNAME}" >/dev/null 2>&1; then
    echo "Removendo CSR antiga: ${USERNAME}"
    kubectl delete csr "${USERNAME}"
  fi

  kubectl apply -f "${CSR_YAML}"

  kubectl certificate approve "${USERNAME}"

  echo "Aguardando emissão do certificado..."

  for ATTEMPT in $(seq 1 30); do
    CERTIFICATE_DATA="$(
      kubectl get csr "${USERNAME}" \
        -o jsonpath='{.status.certificate}' 2>/dev/null || true
    )"

    if [[ -n "${CERTIFICATE_DATA}" ]]; then
      break
    fi

    sleep 2
  done

  if [[ -z "${CERTIFICATE_DATA:-}" ]]; then
    echo "ERRO: certificado não foi emitido para ${USERNAME}."
    kubectl describe csr "${USERNAME}"
    exit 1
  fi

  printf '%s' "${CERTIFICATE_DATA}" |
    base64 --decode > "${CERT_FILE}"

  chmod 644 "${CERT_FILE}"

  echo "Certificado salvo em: ${CERT_FILE}"

  openssl x509 \
    -in "${CERT_FILE}" \
    -noout \
    -subject \
    -issuer \
    -dates
done

echo
echo "Certificados gerados com sucesso."
kubectl get csr