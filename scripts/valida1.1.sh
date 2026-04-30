#!/usr/bin/env bash
set -euo pipefail

# Diretório base
BASE_DIR="evidencias/semana-1/etapa-1.1"

echo "==> Criando diretórios..."
mkdir -p "$BASE_DIR"

echo "==> 1) Containers rodando"
docker ps > "$BASE_DIR/02-docker-ps.txt"

echo "==> 2) Health checks"
{
  echo "### api-contas"
  curl -s http://localhost:8081/health/live

  echo -e "\n\n### api-transacoes"
  curl -s http://localhost:8082/health/live

  echo -e "\n\n### auditoria"
  curl -s http://localhost:8083/health/live

  echo -e "\n\n### web"
  curl -s http://localhost:8080/healthz

  echo
} > "$BASE_DIR/03-health-checks.txt"

echo "==> 3) Listar contas"
curl -s http://localhost:8081/contas | jq . \
  > "$BASE_DIR/04-contas.json"

echo "==> 4) Login com sucesso"
curl -s -i -X POST http://localhost:8081/login \
  -H 'content-type: application/json' \
  -d '{"documento":"12345678901","senha":"giropops"}' \
  > "$BASE_DIR/05-login-sucesso.txt"

echo "==> 5) Login com erro"
curl -s -i -X POST http://localhost:8081/login \
  -H 'content-type: application/json' \
  -d '{"documento":"12345678901","senha":"senhaerrada"}' \
  > "$BASE_DIR/06-login-erro.txt"

echo "==> 6) Criar conta nova"
curl -s -i -X POST http://localhost:8081/contas \
  -H 'content-type: application/json' \
  -d '{
    "titular":"Teste Evidencia",
    "documento":"99999999999",
    "senha":"123456",
    "saldo_inicial":"500.00"
  }' \
  > "$BASE_DIR/07-criar-conta.txt"

echo "==> 7) Fazer transferência"
curl -s -i -X POST http://localhost:8082/transferencias \
  -H 'content-type: application/json' \
  -d '{
    "origem_id":"11111111-1111-1111-1111-111111111111",
    "destino_id":"22222222-2222-2222-2222-222222222222",
    "valor":"100.00"
  }' \
  > "$BASE_DIR/08-transferencia.txt"

echo "==> 8) Ver eventos pela API de auditoria"
curl -s http://localhost:8083/eventos | jq . \
  > "$BASE_DIR/09-auditoria.json"

echo "==> 9) Ver arquivo físico dentro do container de auditoria"
AUDITORIA_CONTAINER=$(docker ps --format '{{.Names}}' | grep -i auditoria | head -n1)

{
  echo "Container auditoria: $AUDITORIA_CONTAINER"
  echo

  echo "### Arquivos em /data"
  docker exec "$AUDITORIA_CONTAINER" ls -lah /data

  echo
  echo "### Conteúdo eventos"
  docker exec "$AUDITORIA_CONTAINER" sh -c 'cat /data/eventos-*.jsonl 2>/dev/null || true'
} > "$BASE_DIR/10-arquivo-auditoria.txt"

echo "==> 10) Conferir arquivos gerados"
ls -lah "$BASE_DIR"

echo "==> Finalizado com sucesso!"