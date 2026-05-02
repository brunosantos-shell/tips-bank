#!/usr/bin/env bash
set -euo pipefail

DATA="$(date +%Y%m%d-%H%M%S)"
OUT="evidencias-${DATA}"
mkdir -p "$OUT"

IMAGES=(
  "tipsbank/api-contas:dev"
  "tipsbank/api-transacoes:dev"
  "tipsbank/auditoria:dev"
  "tipsbank/web:dev"
)

PYTHON_IMAGES=(
  "tipsbank/api-contas:dev"
  "tipsbank/api-transacoes:dev"
  "tipsbank/auditoria:dev"
)

WEB_IMAGE="tipsbank/web:dev"

echo "Gerando evidências em: $OUT"

{
  echo "Data: $(date)"
  echo "Host: $(hostname)"
  echo
  echo "Imagens avaliadas:"
  printf '%s\n' "${IMAGES[@]}"
} | tee "$OUT/00-contexto.txt"

echo "==> Evidência 1: Trivy HIGH/CRITICAL"
for img in "${IMAGES[@]}"; do
  safe_name="$(echo "$img" | tr '/:' '__')"

  {
    echo "Imagem: $img"
    echo "Comando: trivy image --severity HIGH,CRITICAL --exit-code 1 $img"
    echo
    trivy image --severity HIGH,CRITICAL  --exit-code 1 "$img"
    echo
    echo "Resultado: OK - 0 vulnerabilidades HIGH/CRITICAL"
  } | tee "$OUT/01-trivy-${safe_name}.txt"
done

echo "==> Evidência 2: usuário não-root via docker inspect"
{
  echo "Validação de usuário final configurado na imagem"
  echo
  printf "%-35s %-15s %-15s %-10s\n" "IMAGE" "USER_ATUAL" "USER_ESPERADO" "STATUS"

  for img in "${PYTHON_IMAGES[@]}"; do
    user="$(docker inspect "$img" --format='{{.Config.User}}')"
    expected="65532"

    if [[ "$user" == "$expected" ]]; then
      status="OK"
    else
      status="FALHA"
    fi

    printf "%-35s %-15s %-15s %-10s\n" "$img" "$user" "$expected" "$status"
  done

  user="$(docker inspect "$WEB_IMAGE" --format='{{.Config.User}}')"
  expected="101"

  if [[ "$user" == "$expected" ]]; then
    status="OK"
  else
    status="FALHA"
  fi

  printf "%-35s %-15s %-15s %-10s\n" "$WEB_IMAGE" "$user" "$expected" "$status"
} | tee "$OUT/02-docker-inspect-usuarios.txt"

echo "==> Evidência 3: tamanho das imagens"
{
  echo "Validação de tamanho final das imagens"
  echo
  printf "%-35s %-15s %-15s %-10s\n" "IMAGE" "SIZE_MB" "LIMITE_MB" "STATUS"

  for img in "${PYTHON_IMAGES[@]}"; do
    size_bytes="$(docker image inspect "$img" --format='{{.Size}}')"
    size_mb="$(awk -v s="$size_bytes" 'BEGIN { printf "%.2f", s/1024/1024 }')"
    limit="150"

    if awk -v s="$size_mb" -v l="$limit" 'BEGIN { exit !(s < l) }'; then
      status="OK"
    else
      status="FALHA"
    fi

    printf "%-35s %-15s %-15s %-10s\n" "$img" "$size_mb" "$limit" "$status"
  done

  size_bytes="$(docker image inspect "$WEB_IMAGE" --format='{{.Size}}')"
  size_mb="$(awk -v s="$size_bytes" 'BEGIN { printf "%.2f", s/1024/1024 }')"
  limit="30"

  if awk -v s="$size_mb" -v l="$limit" 'BEGIN { exit !(s < l) }'; then
    status="OK"
  else
    status="FALHA"
  fi

  printf "%-35s %-15s %-15s %-10s\n" "$WEB_IMAGE" "$size_mb" "$limit" "$status"
} | tee "$OUT/03-tamanho-imagens.txt"

echo "==> Gerando pacote final"
tar -czf "${OUT}.tar.gz" "$OUT"

echo
echo "Evidências geradas:"
echo "$OUT/"
echo "${OUT}.tar.gz"
