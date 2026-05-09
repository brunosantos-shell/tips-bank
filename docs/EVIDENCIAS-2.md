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

---

### **Etapa 2.2 — TLS com cert-manager + recursos avançados do Ingress**

### Objetivo da Etapa

Implementar HTTPS nos Ingresses utilizando `cert-manager`, além de aplicar recursos avançados do Ingress Nginx:

- TLS para os hosts da aplicação
- Basic Auth na rota administrativa
- Rate limit no frontend
- Affinity Cookie na API de transações

### 1. Instalação do cert-manager

Foi realizada a instalação do `cert-manager` no cluster Kubernetes para gerenciamento automático de certificados TLS.

```bash
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set crds.enabled=true
```

- 🖼️ Instalaçao Certmanager: `install-certmanager.png`

![alt text](../evidencias/semana-2/etapa-2.2/install-certmanager.png)

- 🖼️ Cert-manager instalado: `cert-manager-pods.png`

![alt text](../evidencias/semana-2/etapa-2.2/cert-manager-pods.png)

### 2. Criação do ClusterIssuer

Foi criado um ClusterIssuer do tipo self-signed para emissão de certificados no ambiente de laboratório.

- 🖼️ ClusterIssuer criado: clusterissuer.png

![alt text](../evidencias/semana-2/etapa-2.2/clusterissuer.png)

### 3. Configuração de TLS nos Ingresses

Foram adicionadas as configurações de TLS nos Ingresses da aplicação, utilizando o ClusterIssuer criado anteriormente.

Hosts protegidos com HTTPS:
- app.tipsbank.local
- api.tipsbank.local

Configuração aplicada:

```bash
tls:
  - hosts:
      - app.tipsbank.local
    secretName: app-tipsbank-tls

tls:
  - hosts:
        - api.tipsbank.local
    secretName: api-contas-tipsbank-tls
```

- 🖼️ Certificates Certmanager: `certificates.png`

![alt text](../evidencias/semana-2/etapa-2.2/certificates.png)

### 4. Validação HTTPS do Frontend

Foi validado o acesso HTTPS ao frontend da aplicação.

Comando executado:
curl -vk https://app.tipsbank.local/

- 🖼️ Check SSL Certmanager: `check-cert-ssl.png`

![alt text](../evidencias/semana-2/etapa-2.2/check-cert-ssl.png)

### 5. Configuração de Basic Auth na Rota Administrativa

Foi criada proteção com Basic Auth para a rota administrativa:

```
https://api.tipsbank.local/contas/admin/

htpasswd -bc auth admin admin123

kubectl create secret generic basic-auth \
  --from-file=auth \
  -n tipsbank-contas
```

- 🖼️ Secret Basic Auth:

![Secret Basic Auth](../evidencias/semana-2/etapa-2.2/basic-auth-secret.png)

- 🖼️ Ingress protegido com Basic Auth:

![Ingress Basic Auth](../evidencias/semana-2/etapa-2.2/ingress-basic-auth.png)

- 🖼️ Teste sem autenticação (401):

![Teste 401 Basic Auth](../evidencias/semana-2/etapa-2.2/basic-auth-401.png)

- 🖼️ Teste autenticado (200):

![Teste 200 Basic Auth](../evidencias/semana-2/etapa-2.2/basic-auth-200.png)


### 6. Configuração de Rate Limit no Frontend

Foi aplicado rate limit global no Ingress do frontend para proteção da entrada principal da aplicação.

Annotation utilizada:

```yaml
nginx.ingress.kubernetes.io/limit-rps: "50"
nginx.ingress.kubernetes.io/limit-burst-multiplier: "1"
```

- 🖼️ Ingress com rate limit: `ingress-rate-limit.png`

![alt text](../evidencias/semana-2/etapa-2.2/ingres-rate-limit.png)

### 7. Validação do Rate Limit

Foi executado teste de carga com rajada de requisições para validar o bloqueio após o limite configurado.

```bash
ab -n 100 -c 100 https://app.tipsbank.local/
```

- 🖼️ Teste de rate limit: `rate-limit-test.png`

![alt text](../evidencias/semana-2/etapa-2.2/rate-limit-test.png)

### 8. Configuração de Affinity Cookie em Transações

Foi configurada afinidade por cookie na rota da API de transações.

Annotation utilizada:

```yaml
nginx.ingress.kubernetes.io/affinity: cookie
```

Objetivo:

Garantir que requisições da mesma sessão sejam encaminhadas para o mesmo pod da api-transacoes.

- 🖼️ Ingress transações com affinity: `ingress-affinity-cookie.png`

![alt text](../evidencias/semana-2/etapa-2.2/ingress-affinity-cookie.png)

### 9. Validação de Upstream Hashing / Affinity

Foi realizado teste para validar que requisições com o mesmo cookie permanecem direcionadas ao mesmo backend.

- 🖼️ Teste de affinity: `affinity-test.png`

![alt text](../evidencias/semana-2/etapa-2.2/affinnity-test.png)

### 10. Referência dos Manifestos Kubernetes (YAML)

Os seguintes manifestos foram utilizados nesta etapa:

- 📄 Cert-manager / ClusterIssuer:[01-clusterissuer-selfsigned.yaml](../k8s/etapa-2.2/01-clusterissuer-selfsigned.yaml)
- 📄 Ingress Web com TLS e Rate Limit:[02-ingress-web-tls-ratelimit.yaml](../k8s/etapa-2.2/02-ingress-web.yaml)
- 📄 Ingress Contas: [03-ingress-contas.yaml](../k8s/etapa-2.2/03-ingress-contas.yaml)
- 📄 Ingress Admin com Basic Auth: [04-ingress-contas-admin.yaml](../k8s/etapa-2.2/04-ingress-contas-admin.yaml)
- 📄 Ingress Transações com Affinity Cookie: [05-ingress-transacoes.yaml](../k8s/etapa-2.2/05-ingress-transacoes.yaml)
- 📄 Ingress Auditoria: [06-ingress-auditoria.yaml](../k8s/etapa-2.2/06-ingress-auditoria.yaml)
- 📄 Config Secret Basic Auth: [07-basic-auth-secret.yaml](../k8s/etapa-2.2/07-basic-auth-secret.yaml)


### Conclusão
- ✔ cert-manager instalado e operacional no cluster
- ✔ ClusterIssuer self-signed configurado para emissão de certificados TLS
- ✔ HTTPS funcional nos hosts app.tipsbank.local e api.tipsbank.local
- ✔ Frontend validado via HTTPS com retorno HTTP 200
- ✔ Rota administrativa protegida com Basic Auth
- ✔ Acesso sem credenciais retornando 401 e acesso autenticado retornando 200
- ✔ Rate limit configurado no frontend com retorno 429 em rajadas acima do limite
- ✔ Affinity Cookie aplicada na rota de transações
- ✔ Upstream hashing / afinidade de sessão validado e documentado