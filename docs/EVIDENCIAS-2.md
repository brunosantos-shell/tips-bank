# Evidências Semana 2
**Projeto:** TipsBank  
**Objetivo da semana:** Expor o TipsBank ao mundo via Ingress Nginx com TLS, replicar a app no EKS, e aplicar NetworkPolicies zero-trust entre namespaces.
**Data:** 04/05/2026  
**Responsável:** Bruno dos Santos

---

### **Etapa 2.1 Ingress Nginx + múltiplos hosts** 

### Objetivo da Etapa

Implementar o Ingress Nginx Controller para exposição centralizada da aplicação TipsBank utilizando múltiplos hosts:

- `app.tipsbank.local` → frontend (SPA)
- `api.tipsbank.local` → acesso direto às APIs via paths

### 1. Instalação do Ingress Nginx Controller

Foi realizado o deploy do Ingress Nginx Controller no cluster Kubernetes utilizando os manifestos oficiais.

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  -n ingress-nginx \
  --create-namespace

kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx
kubectl get svc -n ingress-nginx ingress-nginx-controller
```

- 🖼️ Checando o Ingress no K8S: `chek_ingress.png`

![alt text](../evidencias/semana-2/etapa-2.1/check_ingress.png)

### 2. Configuração dos Hosts Locais

Foi configurado o arquivo `/etc/hosts` da estação local apontando os hosts da aplicação para o IP do Ingress Controller.

### Configuração aplicada:

```txt
192.168.20.200 app.tipsbank.local api.tipsbank.local
```

- 🖼️ Configuração do hosts local: `hosts.png`

![alt text](../evidencias/semana-2/etapa-2.1/hosts.png)

### 3. Configuração dos Recursos Ingress

Foram criados recursos Ingress separados para frontend e APIs.

Hosts configurados

Frontend
- app.tipsbank.local
    - encaminhando para svc/web
    - namespace: tipsbank-web

APIs
- api.tipsbank.local

Com os seguintes paths:

- /contas/*
    - svc/api-contas
    - namespace: tipsbank-contas
- /transacoes/*
    - svc/api-transacoes
    - namespace: tipsbank-transacoes
- /auditoria/*
    - svc/auditoria
    - namespace: tipsbank-auditoria

- 🖼️ Recursos ingress criados:`ingress.png`

![alt text](../evidencias/semana-2/etapa-2.1/ingress.png)

### 4. Validação de Acesso às APIs via Ingress

Foi realizado acesso direto às APIs utilizando o host api.tipsbank.local.

```bash
curl -H 'Host: api.tipsbank.local' \
http://192.168.20.200/contas/contas | jq
```

- 🖼️ Listagem de contas via ingress: `listar-contas-ingress.png`

![alt text](../evidencias/semana-2/etapa-2.1/listar-contas-ingress.png)

### 5. Validação de Healthcheck

```bash
curl -H 'Host: api.tipsbank.local' \
http://192.168.20.200/contas/health/live

curl -H 'Host: api.tipsbank.local' \
http://192.168.20.200/transacoes/health/live

curl -H 'Host: api.tipsbank.local' \
http://192.168.20.200/auditoria/health/live

curl -H 'Host: app.tipsbank.local' \
http://192.168.20.200/healthz
```

- 🖼️ Healthcheck APIs: `health-check-api.png`

![alt text](../evidencias/semana-2/etapa-2.1/health-check-api.png)

- 🖼️ Healthcheck Web: `health-check-web.png`

![alt text](../evidencias/semana-2/etapa-2.1/health-check-web.png)

- 🖼️ SPA acessível via Ingress: `web-ingress.png`

![alt text](../evidencias/semana-2/etapa-2.1/web-ingress.png)

### 7. Referência dos Manifestos Kubernetes (YAML)
- 📄 Ingress WEB: [ingress-web.yaml](../k8s/etapa-2.1/ingress-web.yaml)
- 📄 Ingress API-CONTAS: [ingress-contas.yaml](../k8s/etapa-2.1/ingress-contas.yaml)
- 📄 Ingress API-TRANSAÇOES: [ingress-transacoes.yaml](../k8s/etapa-2.1/ingress-transacoes.yaml)
- 📄 Ingress API-AUDITORIA: [ingress-auditoria.yaml](../k8s/etapa-2.1/ingress-auditoria.yaml)

### Conclusão
- ✔ Ingress Nginx Controller implantado com sucesso no cluster
- ✔ Hosts app.tipsbank.local e api.tipsbank.local configurados e funcionais
- ✔ APIs expostas externamente via paths utilizando Ingress
- ✔ Frontend acessível via host dedicado
- ✔ Comunicação entre frontend e backend validada via Ingress
- ✔ Healthchecks das APIs e frontend funcionando corretamente
- ✔ Resolução local configurada via /etc/hosts