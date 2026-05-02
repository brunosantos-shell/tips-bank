# Evidências Semana 1 / 
**Projeto:** TipsBank  
**Objetivo da Etapa:** Entender a aplicação localmente rodando via docker-compose  
**Data:** 02/05/2026  
**Responsável:** Bruno dos Santos

### **Etapa 1.1 Entender a aplicação localmente** 

### Objetivo da Etapa

Rodar a aplicação TipsBank localmente utilizando Docker Compose e validar o funcionamento completo (frontend + APIs + auditoria), sendo capaz de explicar o fluxo entre os serviços.

### 1. Inicialização do Ambiente (Docker Compose)

### Comando executado:

```bash
docker compose up --build
```

- 📄 Log de execução: [01-docker-compose-up.log](../evidencias/semana-1/etapa-1.1/01-docker-compose-up.log)

### 2. Acesso ao Frontend (SPA)

URL de acesso ao Frotend

```
http://localhost:8080
```

- 🖼️ Dashboard no Login: `01-dashboard.png`

![Dashboard no Login](../evidencias/semana-1/etapa-1.1/01-dashboard.png)

- 🖼️ Dashboard usuário logado: `02-dashboard_user.png`

![Dashboard user](../evidencias/semana-1/etapa-1.1/02-dashboard_user.png)

### 3. Criação de Conta

Criação de nova conta via API

- 📄 Log de execução: [07-criar-conta.txt](../evidencias/semana-1/etapa-1.1/07-criar-conta.txt)

### 4. Autenticação

Teste de login (sucesso):

```bash
curl -X POST http://localhost:8081/login \
-H 'content-type: application/json' \
-d '{"documento":"12345678901","senha":"giropops"}'
```

- 📄 Login sucesso: [05-login-sucesso.txt](../evidencias/semana-1/etapa-1.1/05-login-sucesso.txt)

- 📄 Login erro: [06-login-erro.txt](../evidencias/semana-1/etapa-1.1/06-login-erro.txt)

### 5. Listagem de Contas

```bash
curl http://localhost:8081/contas
```

📄 Arquivo: [04-contas.json](../evidencias/semana-1/etapa-1.1/04-contas.json)

### 6. Transferência entre Contas

Execução de transferência no valor de R$ 100,00 entre contas distintas via API

- 📄 Log via curl: [08-transferencia.txt](../evidencias/semana-1/etapa-1.1/08-transferencia.txt)

- 🖼️ Dashboard Transferencias `03-transferencia.png`

![alt text](../evidencias/semana-1/etapa-1.1/03-transferencia.png)

### 7. Auditoria de Eventos

- 📄 JSON: [09-auditoria.json](../evidencias/semana-1/etapa-1.1/09-auditoria.json)

- 🖼️ Dashboard Auditoria `04-Auditoria.png`

![alt text](../evidencias/semana-1/etapa-1.1/04-Auditoria.png)

### 8. Validação de Healthcheck das APIs

- 📄 Log via curl: 
[03-health-checks.txt](../evidencias/semana-1/etapa-1.1/03-health-checks.txt)

### 9. Execução de Testes Automatizados

- 📄Script Shell: [valida1.1.sh](../scripts/valida1.1.sh)

### Conclusão

- ✔ Ambiente provisionado com sucesso via Docker Compose  
- ✔ Frontend (SPA) acessível e integrado aos serviços backend  
- ✔ APIs de contas e autenticação validadas (HTTP 200 / 401, bcrypt)  
- ✔ Listagem de contas funcional sem exposição de dados sensíveis  
- ✔ Transferências realizadas com consistência de saldo  
- ✔ Eventos de auditoria gerados e persistidos em `.json`  
- ✔ Healthchecks indicando serviços disponíveis e saudáveis  
- ✔ Testes automatizados executados com sucesso  
- ✔ Fluxo de ponta a ponta validado entre frontend e microserviços  

---

### **Etapa 1.2 Build Distroless, Scan com Trivy e Assinatura Cosign**

### Objetivo da Etapa

Construir 4 imagens de container do projeto TipsBank, sendo 3 APIs utilizando runtime Distroless e 1 frontend utilizando nginx-unprivileged nonroot, garantindo:

- Zero vulnerabilidades HIGH/CRITICAL no Trivy
- Imagens assinadas com Cosign
- Execução com usuário não-root
- Tamanho final dentro dos critérios definidos

---

### 1. Build das Imagens

### Descrição

Foi realizado o build das imagens das aplicações TipsBank:

- `api-contas`
- `api-transacoes`
- `auditoria`
- `web`

As APIs utilizam Dockerfile multi-stage, separando a etapa de build da etapa de runtime. No builder é utilizada uma imagem Python com ferramentas de compilação, enquanto no runtime é utilizada imagem Distroless, reduzindo a superfície de ataque.

- 📄 Log de build: [build-cosing.txt](../evidencias/semana-1/etapa-1.2/build-cosing.txt)

---

### 2. Justificativa Técnica do Uso de Distroless

As imagens Distroless reduzem vulnerabilidades porque removem componentes desnecessários do sistema operacional, como shell, gerenciadores de pacotes e ferramentas administrativas.

No caso das APIs Python, o build utiliza `pip install --target=/packages` em vez de ambiente virtual (`venv`). Isso evita problemas no runtime Distroless, onde o binário `python3` está em caminho diferente. A aplicação passa a utilizar:

```bash
PYTHONPATH=/packages
PATH=/packages/bin:$PATH
```

### 3. Scan de Vulnerabilidades com Trivy


Inicialmente, foi realizado o scan de vulnerabilidades nas imagens construídas utilizando base Distroless padrão.

Comando utilizado:
trivy image --severity HIGH,CRITICAL <imagem>
Evidências (primeira análise):
- 📄 API Contas: [trivy-api-contas.txt](../evidencias/semana-1/etapa-1.2/06-trivy-api-contas.txt)
- 📄 API Transações: [trivy-api-transacoes.txt](../evidencias/semana-1/etapa-1.2/07-trivy-api-transacoes.txt)
- 📄 Auditoria: [trivy-auditoria.txt](../evidencias/semana-1/etapa-1.2/08-trivy-auditoria.txt)
- 📄 Web: [trivy-web.txt](../evidencias/semana-1/etapa-1.2/09-trivy-web.txt)

Resultado (primeira execução):

✖ Foram identificadas vulnerabilidades HIGH e/ou CRITICAL nas imagens iniciais
✖ Critério de aceite ainda não atendido

### 4. Mitigação de Vulnerabilidades (Uso de Imagens Chainguard)

Para atender ao requisito de segurança da etapa (0 vulnerabilidades HIGH/CRITICAL), foi realizada a substituição das imagens base por imagens da Chainguard (Wolfi), conhecidas por:

Ciclo rápido de atualização de segurança
Redução de CVEs conhecidas
Imagens minimalistas e voltadas para segurança

As imagens foram reconstruídas utilizando essa nova base.

Resultado:

✔ Redução significativa da superfície de vulnerabilidades
✔ Uso de imagens hardened e atualizadas

### 5. Novo Scan com Trivy (Imagens Chainguard)

Após a substituição das imagens base, foi executado um novo scan com Trivy.

- 📄 API Contas: [trivy-api-contas-chainguard.txt](../evidencias/semana-1/etapa-1.2/trivy-api-contas-chainguardtxt)
- 📄 API Transações: [trivy-api-transacoes-chainguard.txt](../evidencias/semana-1/etapa-1.2/trivy-api-transacoes-chaiguard.txt)
- 📄 Auditoria: [trivy-auditoria-chainguard.txt](../evidencias/semana-1/etapa-1.2/trivy-auditoria-chainguard.txt)
- 📄 Web: [trivy-web-chainguard.txt](../evidencias/semana-1/etapa-1.2/trivy-web-chaiguard.txt)

- 🖼️ Scan no trivy apresentando 0 erros de vulnerabilidades

![alt text](../evidencias/semana-1/etapa-1.2/trivy-scan-OK.png)

### 6. Validação de Usuário Não-Root

```bash
docker inspect <imagem>
```

- 📄 [docker-inspect-usuarios.txt](../evidencias/semana-1/etapa-1.2/02-docker-inspect-usuarios.txt)


### 7. Validação do Tamanho das Imagens

Critério esperado:
- Imagens Python: menores que 150 MB
- Imagem Web: menor que 30 MB

- 📄 [tamanho-imagens.txt](../evidencias/semana-1/etapa-1.2/03-tamanho-imagens.txt)

![alt text](../evidencias/semana-1/etapa-1.2/tamanho-imagens.png)

### 8. Assinatura das Imagens com Cosign e Verificação das Assinaturas

```bash
cosign sign <imagem>
cosign verify <imagem>
```

Após o build e publicação das imagens, foi realizada a assinatura utilizando Cosign.

Evidência:
- 📄 Log de assinatura: [build-cosign.txt](../evidencias/semana-1/etapa-1.2/build-cosing.txt)

- 🖼️ Execuçao do script [build-e-assinar.sh](../scripts/build-e-assinar.sh)
![alt text](../evidencias/semana-1/etapa-1.2/image.png)
![alt text](../evidencias/semana-1/etapa-1.2/image-1.png)
![alt text](../evidencias/semana-1/etapa-1.2/image-2.png)
![alt text](../evidencias/semana-1/etapa-1.2/image-3.png)
![alt text](../evidencias/semana-1/etapa-1.2/image-4.png)
![alt text](../evidencias/semana-1/etapa-1.2/image-5.png)
![alt text](../evidencias/semana-1/etapa-1.2/image-6.png)
![alt text](../evidencias/semana-1/etapa-1.2/image-7.png)

### 9. Execução de Testes Automatizados

- 📄Script Shell: [valida1.2.sh](../scripts/valida1.2.sh)

### Conclusão

### Resultado:

- ✔ Build das 4 imagens do projeto (api-contas, api-transacoes, auditoria e web) utilizando Docker multi-stage
- ✔ Utilização de runtime Distroless para redução da superfície de ataque
- ✔ Ajuste técnico no build Python utilizando pip install --target=/packages (compatível com Distroless)
- ✔ Execução inicial do Trivy, identificando vulnerabilidades HIGH/CRITICAL nas imagens base
- ✔ Adoção de imagens Chainguard (Wolfi) para mitigação de vulnerabilidades
- ✔ Rebuild completo das imagens com base Chainguard
- ✔ Novo scan com Trivy validando 0 vulnerabilidades HIGH e 0 CRITICAL
- ✔ Assinatura das imagens utilizando Cosign
- ✔ Verificação das assinaturas com cosign verify
- ✔ Execução das aplicações com usuário não-root (UID 65532 / 101)
- ✔ Validação do tamanho das imagens dentro dos limites definidos

---

### **Etapa 1.3 Cluster kubeadm multi-node**