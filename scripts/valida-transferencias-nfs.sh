 kubectl port-forward -n tipsbank-auditoria svc/auditoria 8083:8080 &

for i in $(seq -w 1 50); do
  UUID_TX=$(uuidgen)
  VALOR=$(awk -v min=0.10 -v max=5 'BEGIN{srand(); printf "%.2f", min+rand()*(max-min)}')

  curl -s -X POST http://localhost:8083/eventos \
    -H "Content-Type: application/json" \
    -d "{
      \"tipo\":\"transferencia\",
      \"transacao_id\":\"$i-$UUID_TX\",
      \"origem_id\":\"22222222-2222-2222-2222-222222222222\",
      \"destino_id\":\"11111111-1111-1111-1111-111111111111\",
      \"valor\":\"$VALOR\",
      \"versao_app\":\"v1\"
    }" &

done

kill -9 %1