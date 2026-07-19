# Evidências Semana 4
**Projeto:** TipsBank  
**Objetivo da semana:** aplicar compliance de banco via Kyverno, segregar acessos com RBAC (certificados + SA/Token), empacotar TUDO num Helm Chart umbrella  
**Data:** 23/05/2026  
**Responsável:** Bruno dos Santos

---

### **Etapa 4.1 — Kyverno: Validate (Proibir Root e Tag Latest)**

### Objetivo da Etapa

Implementar políticas de validação utilizando **Kyverno** para aumentar a segurança do cluster Kubernetes, impedindo a criação de workloads que não estejam em conformidade com os padrões definidos.

Nesta etapa foram implementadas políticas para:

- Proibir containers executando como usuário root (`runAsUser: 0`)
- Proibir imagens utilizando a tag `latest`
- Exigir labels obrigatórias em Deployments, StatefulSets e DaemonSets

Todas as políticas foram configuradas em modo **Enforce**, impedindo a criação de recursos que violem as regras.

### 1. Instalação do Kyverno

Foi realizada a instalação do Kyverno utilizando Helm.

### Comandos utilizados

```bash
helm repo add kyverno https://kyverno.github.io/kyverno

helm repo update

helm install kyverno kyverno/kyverno \
-n kyverno \
--create-namespace
```

Validação:

```bash
kubectl rollout status deployment \
-n kyverno
```

### Evidência

🖼️ Rollout do Kyverno concluído:

![kubectl-rollout-status-kyverno.png](../evidencias/semana-4/etapa-4.1/kubectl-rollout-status-kyverno.png)

### Resultado

- ✔ Kyverno instalado com sucesso
- ✔ Controladores iniciados
- ✔ Admission Controller operacional

### 2. Validação dos Pods do Kyverno

Foi validado que todos os componentes do Kyverno encontram-se em execução.

### Comando utilizado

```bash
kubectl get pods -n kyverno
```

### Evidência

🖼️ Pods do Kyverno:

![kubectl-get-pods-kyverno.png](../evidencias/semana-4/etapa-4.1/kubectl-get-pods-kyverno.png)

### Resultado

- ✔ Todos os pods em estado Running
- ✔ Componentes operacionais

### 3. Validação do Admission Webhook

Foi validado que o Admission Webhook responsável pela aplicação das políticas foi criado corretamente.

### Comando utilizado

```bash
kubectl get validatingwebhookconfiguration
```

### Evidência

🖼️ Validating Webhook:

![kubectl-get-validatingwebhookconfiguration-kyverno.png](../evidencias/semana-4/etapa-4.1/kubectl-get-validatingwebhookconfiguration-kyverno.png)

### Resultado

- ✔ Admission Webhook registrado
- ✔ Políticas sendo interceptadas durante criação dos recursos

### 4. Criação da ClusterPolicy — Disallow Root User

Foi criada uma política para impedir a criação de workloads executando como usuário root.

Modo utilizado:

```text
Enforce
```

Objetivo:

Impedir configurações contendo:

```yaml
securityContext:
  runAsUser: 0
```

Validação:

```bash
kubectl describe clusterpolicy disallow-root-user
```

### Evidência

🖼️ Policy disallow-root-user:

![kubectl-describe-clusterpolicy-disallow-root-user.png](../evidencias/semana-4/etapa-4.1/kubectl-describe-clusterpolicy-disallow-root-user.png)

### Resultado

- ✔ Política criada
- ✔ Status Ready=True
- ✔ Modo Enforce habilitado

### 5. Criação da ClusterPolicy — Disallow Latest Tag

Foi criada uma política para impedir utilização de imagens utilizando a tag `latest`.

Objetivo:

Evitar implantações sem versionamento definido.

Exemplo bloqueado:

```yaml
image: nginx:latest
```

Validação:

```bash
kubectl describe clusterpolicy disallow-latest-tag
```

### Evidência

🖼️ Policy disallow-latest-tag:

![kubectl-describe-clusterpolicy-disallow-latest-tag.png](../evidencias/semana-4/etapa-4.1/kubectl-describe-clusterpolicy-disallow-latest-tag.png)

### Resultado

- ✔ Política criada
- ✔ Status Ready=True
- ✔ Modo Enforce habilitado

### 6. Criação da ClusterPolicy — Require Labels

Foi criada uma política exigindo a presença das labels obrigatórias em todos os Deployments, StatefulSets e DaemonSets.

Labels obrigatórias:

- app
- team
- env

Validação:

```bash
kubectl describe clusterpolicy require-labels
```

### Evidência

🖼️ Policy require-labels:

![kubectl-describe-clusterpolicy-require-labels.png](../evidencias/semana-4/etapa-4.1/kubectl-describe-clusterpolicy-require-labels.png)

### Resultado

- ✔ Política criada
- ✔ Labels obrigatórias definidas
- ✔ Status Ready=True

### 7. Validação das ClusterPolicies

Foi validado que todas as políticas encontram-se ativas.

### Comando utilizado

```bash
kubectl get cpol
```

### Evidência

🖼️ ClusterPolicies:

![kubectl-get-clusterpolicy-kyverno.png](../evidencias/semana-4/etapa-4.1/kubectl-get-clusterpolicy-kyverno.png)

### Resultado

- ✔ disallow-root-user
- ✔ disallow-latest-tag
- ✔ require-labels

Todas apresentando:

```text
READY=True
```

### 8. Teste da Política Disallow Latest

Foi realizada tentativa de criação de um Pod utilizando imagem com tag `latest`.

Comando executado:

```bash
kubectl run ruim \
--image=nginx:latest
```

Resultado esperado:

```text
Error from server

admission webhook denied the request
```

### Evidência

🖼️ Política bloqueando imagem latest:

![teste-disallow-latest-policy.png](../evidencias/semana-4/etapa-4.1/teste-disallow-latest-policy.png)

### Resultado

- ✔ Criação bloqueada
- ✔ Política funcionando corretamente

### 9. Teste da Política Disallow Root User

Foi realizada tentativa de criação de workload executando como usuário root.

Exemplo:

```yaml
securityContext:
  runAsUser: 0
```

Resultado esperado:

```text
admission webhook denied the request
```

### Evidência

🖼️ Política bloqueando Root User:

![teste-disallow-root-policy.png](../evidencias/semana-4/etapa-4.1/teste-disallow-root-policy.png)

### Resultado

- ✔ Recurso rejeitado
- ✔ Execução como root bloqueada

### 10. Teste da Política Require Labels

Foi realizada tentativa de criação de Deployment sem as labels obrigatórias.

Resultado esperado:

```text
admission webhook denied the request
```

### Evidência

🖼️ Política Require Labels:

![teste-require-labels-policy.png](../evidencias/semana-4/etapa-4.1/teste-require-labels-policy.png)

### Resultado

- ✔ Deployment rejeitado
- ✔ Obrigatoriedade de labels validada

### 11. Adequação dos Workloads do TipsBank

Após a criação da ClusterPolicy `require-labels`, foi identificada a necessidade de adequar os workloads já existentes da aplicação TipsBank, adicionando as labels obrigatórias exigidas pela política.

As labels obrigatórias definidas foram:

- `app`
- `team`
- `env`

Para evitar a recriação dos recursos, as labels foram adicionadas diretamente aos objetos em execução utilizando o comando `kubectl label`.

### Comandos utilizados

```bash
kubectl label deployment auditoria \
  -n tipsbank-auditoria \
  app=auditoria team=tipsbank env=lab --overwrite

kubectl label deployment api-contas \
  -n tipsbank-contas \
  app=api-contas team=tipsbank env=lab --overwrite

kubectl label statefulset postgres \
  -n tipsbank-contas \
  app=postgres team=tipsbank env=lab --overwrite

kubectl label statefulset postgres-replica \
  -n tipsbank-contas \
  app=postgres-replica team=tipsbank env=lab --overwrite

kubectl label deployment api-transacoes \
  -n tipsbank-transacoes \
  app=api-transacoes team=tipsbank env=lab --overwrite

kubectl label deployment api-transacoes-v2 \
  -n tipsbank-transacoes \
  app=api-transacoes-v2 team=tipsbank env=lab --overwrite

kubectl label deployment web \
  -n tipsbank-web \
  app=web team=tipsbank env=lab --overwrite

kubectl label deployment locust \
  -n tipsbank-monitoring \
  app=locust team=tipsbank env=lab --overwrite

kubectl label daemonset node-logger \
  -n tipsbank-monitoring \
  app=node-logger team=tipsbank env=lab --overwrite
```

### Resultado

- ✔ Labels adicionadas com sucesso aos workloads do TipsBank
- ✔ Nenhum recurso precisou ser recriado
- ✔ Nenhum pod da aplicação sofreu indisponibilidade durante a alteração
- ✔ Todos os recursos passaram a atender aos requisitos da ClusterPolicy `require-labels`

---

### 12. Validação das Labels Aplicadas

Após a adequação dos workloads, foi realizada a validação das labels configuradas em todos os Deployments, StatefulSets e DaemonSets pertencentes ao projeto TipsBank.

### Comando utilizado

```bash
for ns in \
  tipsbank-auditoria \
  tipsbank-contas \
  tipsbank-monitoring \
  tipsbank-transacoes \
  tipsbank-web
do
  echo
  echo "===== Namespace: $ns ====="

  kubectl get deployment,statefulset,daemonset \
    -n "$ns" \
    --show-labels
done
```

### Evidência

🖼️ Validação das labels dos workloads do TipsBank:

![kubectl-get-workloads-tipsbank-labels.png](../evidencias/semana-4/etapa-4.1/kubectl-get-workloads-tipsbank-labels.png)

### Resultado

Foi validado que todos os workloads próprios da aplicação TipsBank possuem as labels obrigatórias definidas pela política:

```text
app=<nome-do-componente>
team=tipsbank
env=lab
```

Os seguintes recursos foram verificados:

- Deployment `auditoria`
- Deployment `api-contas`
- Deployment `api-transacoes`
- Deployment `api-transacoes-v2`
- Deployment `web`
- Deployment `locust`
- StatefulSet `postgres`
- StatefulSet `postgres-replica`
- DaemonSet `node-logger`

### Resultado da validação

- ✔ Todos os Deployments do TipsBank possuem as labels obrigatórias
- ✔ Todos os StatefulSets do TipsBank possuem as labels obrigatórias
- ✔ Todos os DaemonSets do TipsBank possuem as labels obrigatórias
- ✔ Os workloads permaneceram disponíveis durante toda a adequação
- ✔ Os recursos próprios do TipsBank encontram-se em conformidade com a ClusterPolicy `require-labels`



### 13. Referência dos Manifestos Kubernetes (YAML)

Manifestos utilizados nesta etapa:

- 📄 [01-disallow-root-user.yaml](../k8s/etapa-4.1/01-disallow-root-user.yaml)
- 📄 [02-disallow-latest-tag.yaml](../k8s/etapa-4.1/02-disallow-latest-tag.yaml)
- 📄 [03-require-labels.yaml](../k8s/etapa-4.1/03-require-labels.yaml)

- 📄 [04-pod-latest.yaml](../k8s/etapa-4.1/04-pod-latest.yaml) 
- 📄 [05-pod-root.yaml](../k8s/etapa-4.1/05-pod-root.yaml) 
- 📄 [06-deployment-sem-labels.yaml](../k8s/etapa-4.1/06-deployment-sem-labels.yaml)

### Conclusão

- ✔ Kyverno instalado com sucesso utilizando Helm
- ✔ Admission Webhook operacional no cluster
- ✔ ClusterPolicies criadas em modo **Enforce**
- ✔ Política bloqueando containers executando como root
- ✔ Política impedindo utilização de imagens com tag `latest`
- ✔ Política exigindo labels obrigatórias em Deployments, StatefulSets e DaemonSets
- ✔ Três cenários de violação testados e corretamente rejeitados
- ✔ Todas as ClusterPolicies em estado **READY=True**

---

### **Etapa 4.2 — Kyverno: Mutate — Injeção de SecurityContext**

### Objetivo da Etapa

Implementar uma política do tipo **Mutate** utilizando Kyverno para adicionar automaticamente configurações de segurança aos containers de novos Pods criados no cluster.

A política foi configurada para injetar os seguintes parâmetros:

```yaml
securityContext:
  runAsNonRoot: true
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false
```

Com essa configuração, workloads criados sem um `securityContext` explícito passam a receber automaticamente controles mínimos de segurança.

## 1. Criação da ClusterPolicy Mutate

Foi criada a ClusterPolicy:

```text
mutate-security-context
```

A política utiliza uma regra do tipo `mutate` para modificar novos Pods durante o processo de admissão no cluster.

A mutação é realizada antes da persistência do recurso no Kubernetes, permitindo que os campos obrigatórios sejam adicionados automaticamente.

### Configurações injetadas

```yaml
securityContext:
  runAsNonRoot: true
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false
```

### Resultado esperado

Todo novo Pod criado sem essas configurações deve recebê-las automaticamente por meio do Admission Controller do Kyverno.

### 2. Aplicação da ClusterPolicy

A política foi aplicada no cluster utilizando o manifesto:

```text
01-mutate-security-context.yaml
```

### Comando utilizado

```bash
kubectl apply -f 01-mutate-security-context.yaml
```

### Validação da ClusterPolicy

```bash
kubectl get cpol
```

Para validar especificamente a política criada:

```bash
kubectl get clusterpolicy mutate-security-context
```

Também pode ser utilizada a inspeção detalhada:

```bash
kubectl describe clusterpolicy mutate-security-context
```

### Evidência

🖼️ ClusterPolicy de mutação criada e ativa:

![kubectl-get-cpol.png](../evidencias/semana-4/etapa-4.2/kubectl-get-cpol.png)

### Resultado

- ✔ ClusterPolicy `mutate-security-context` criada
- ✔ Política reconhecida pelo Kyverno
- ✔ Regra de mutação ativa no Admission Controller
- ✔ Política pronta para modificar novos Pods

### 3. Criação do Pod de Teste

Para validar o funcionamento da política, foi criado um Pod NGINX sem configuração explícita de `securityContext`.

O recurso foi criado por meio do manifesto:

```text
02-nginx-teste.yaml
```

### Exemplo simplificado do manifesto

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-mutate
  namespace: default
  labels:
    app: nginx-mutate
    team: tipsbank
    env: lab
spec:
  containers:
    - name: nginx
      image: nginx:1.27-alpine
```

O manifesto não possui os campos abaixo definidos manualmente:

```yaml
runAsNonRoot: true
readOnlyRootFilesystem: true
allowPrivilegeEscalation: false
```

Dessa forma, os valores encontrados posteriormente no Pod comprovam que foram adicionados pelo Kyverno.

### Comando utilizado

```bash
kubectl apply -f 02-nginx-teste.yaml
```

### Validação inicial

```bash
kubectl get pod nginx-mutate
```

Caso o nome definido no manifesto seja apenas `nginx`, utilizar:

```bash
kubectl get pod nginx
```

### Resultado

- ✔ Pod criado a partir de manifesto sem `securityContext`
- ✔ Recurso admitido pelo cluster
- ✔ Política de mutação acionada durante a criação

### 4. Validação do SecurityContext Injetado

Após a criação do Pod, foi realizada a inspeção do recurso armazenado no Kubernetes.

### Comando utilizado

```bash
kubectl get pod nginx-mutate -o yaml
```

Caso o Pod tenha sido criado com o nome `nginx`:

```bash
kubectl get pod nginx -o yaml
```

Para exibir apenas o trecho do `securityContext`:

```bash
kubectl get pod nginx-mutate -o yaml | grep -A10 securityContext
```

Outra forma de validar diretamente os valores:

```bash
kubectl get pod nginx-mutate \
  -o jsonpath='{range .spec.containers[*]}Container: {.name}{"\n"}runAsNonRoot: {.securityContext.runAsNonRoot}{"\n"}readOnlyRootFilesystem: {.securityContext.readOnlyRootFilesystem}{"\n"}allowPrivilegeEscalation: {.securityContext.allowPrivilegeEscalation}{"\n\n"}{end}'
```

### Resultado esperado

```text
Container: nginx
runAsNonRoot: true
readOnlyRootFilesystem: true
allowPrivilegeEscalation: false
```

No YAML do Pod deve constar:

```yaml
securityContext:
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  runAsNonRoot: true
```

### Evidência

🖼️ Pod NGINX com `securityContext` injetado pelo Kyverno:

![kubectl-get-pod-nginx-mutate.png](../evidencias/semana-4/etapa-4.2/kubectl-get-pod-nginx-mutate.png)

### Resultado

- ✔ Pod originalmente criado sem `securityContext`
- ✔ `runAsNonRoot: true` injetado automaticamente
- ✔ `readOnlyRootFilesystem: true` injetado automaticamente
- ✔ `allowPrivilegeEscalation: false` injetado automaticamente
- ✔ Mutação realizada com sucesso pelo Kyverno

### 5. Considerações sobre Execução Non-Root

As imagens Distroless utilizadas nas APIs do TipsBank já executam por padrão com usuário não privilegiado.

O UID utilizado pelas imagens é:

```text
65532
```

Esse comportamento é compatível com:

```yaml
runAsNonRoot: true
```

A configuração impede que o container seja iniciado como usuário root, aumentando a segurança do workload.

### Validação opcional

```bash
kubectl get pod \
  -n tipsbank-contas \
  -l app=api-contas \
  -o jsonpath='{range .items[*]}{.metadata.name}{" => "}{range .spec.containers[*]}{.name}{": runAsNonRoot="}{.securityContext.runAsNonRoot}{"\n"}{end}{end}'
```

Também é possível validar o UID configurado no Pod:

```bash
kubectl get pod \
  -n tipsbank-contas \
  -l app=api-contas \
  -o yaml | grep -A10 securityContext
```

### Resultado

- ✔ Imagens Distroless compatíveis com execução non-root
- ✔ UID não privilegiado utilizado pelas APIs
- ✔ Política compatível com o padrão de segurança das imagens

### 6. Considerações sobre Read-Only Root Filesystem

A configuração:

```yaml
readOnlyRootFilesystem: true
```

impede que o processo do container escreva no filesystem da imagem.

Essa proteção reduz o risco de:

- alteração de arquivos internos da aplicação
- persistência de arquivos maliciosos
- modificação de binários
- escrita em diretórios inesperados
- abuso do filesystem durante uma eventual exploração

Entretanto, aplicações que precisam gravar arquivos temporários ou logs podem apresentar falhas quando o filesystem raiz é somente leitura.

### Diretórios que podem exigir escrita

Exemplos comuns:

```text
/tmp
/var/run
/var/cache
/var/log
/data
```

Para esses casos, devem ser utilizados volumes graváveis, como `emptyDir`.

### Exemplo de configuração

```yaml
spec:
  containers:
    - name: aplicacao
      volumeMounts:
        - name: tmp
          mountPath: /tmp

        - name: cache
          mountPath: /var/cache

  volumes:
    - name: tmp
      emptyDir: {}

    - name: cache
      emptyDir: {}
```

Dessa forma, o filesystem da imagem permanece protegido, enquanto somente os diretórios necessários recebem permissão de escrita.

---

### 7. Adequação das APIs do TipsBank

Após a aplicação da política, foi necessário garantir que as três APIs do TipsBank permanecessem compatíveis com o filesystem raiz em modo somente leitura.

Foram consideradas as seguintes APIs:

- `api-contas`
- `api-transacoes`
- `auditoria`

A API de transações possui também a versão:

```text
api-transacoes-v2
```

Os workloads que necessitam escrita devem utilizar volumes próprios para os diretórios graváveis.

### API de transações

A API de transações já utiliza um volume compartilhado para gravação de logs:

```yaml
volumes:
  - name: app-logs
    emptyDir: {}
```

Exemplo de montagem:

```yaml
volumeMounts:
  - name: app-logs
    mountPath: /var/log/app
```

Essa configuração permite que:

- o container principal grave o log
- o sidecar leia o mesmo arquivo
- o filesystem raiz permaneça somente leitura

### Auditoria

A aplicação de auditoria utiliza volume persistente para armazenamento dos eventos.

Exemplo:

```yaml
volumeMounts:
  - name: auditoria-data
    mountPath: /data
```

A escrita deve permanecer limitada ao volume montado em `/data`.

### API de contas

A API de contas deve realizar escrita apenas em diretórios explicitamente montados ou no banco PostgreSQL, sem necessidade de escrita no filesystem raiz da imagem.

### Resultado

- ✔ APIs compatíveis com execução non-root
- ✔ Diretórios de escrita tratados por volumes
- ✔ Filesystem raiz mantido em modo somente leitura
- ✔ Persistência de dados realizada fora da camada gravável da imagem


### 8. Validação das APIs do TipsBank

Após a aplicação da política e a adequação dos volumes, foram realizados testes de acesso às APIs.

### Verificação dos Pods

```bash
kubectl get pods \
  -n tipsbank-contas \
  -n tipsbank-transacoes \
  -n tipsbank-auditoria
```

Como o `kubectl` normalmente considera somente um namespace por comando, a forma recomendada é:

```bash
for ns in \
  tipsbank-contas \
  tipsbank-transacoes \
  tipsbank-auditoria
do
  echo
  echo "===== Namespace: $ns ====="
  kubectl get pods -n "$ns"
done
```

### Testes de saúde das APIs

```bash
curl -k \
  -H "Host: api.tipsbank.local" \
  https://192.168.20.200/contas/health/live
```

```bash
curl -k \
  -H "Host: api.tipsbank.local" \
  https://192.168.20.200/transacoes/health/live
```

```bash
curl -k \
  -H "Host: api.tipsbank.local" \
  https://192.168.20.200/auditoria/health/live
```

Também podem ser validados os endpoints de prontidão:

```bash
curl -k \
  -H "Host: api.tipsbank.local" \
  https://192.168.20.200/contas/health/ready
```

```bash
curl -k \
  -H "Host: api.tipsbank.local" \
  https://192.168.20.200/transacoes/health/ready
```

```bash
curl -k \
  -H "Host: api.tipsbank.local" \
  https://192.168.20.200/auditoria/health/ready
```

### Resultado esperado

```text
HTTP/1.1 200 OK
```

ou resposta equivalente indicando que a aplicação está saudável.

### Evidência

🖼️ Validação das APIs após aplicação do filesystem read-only:

![validate-api-curl.png](../evidencias/semana-4/etapa-4.2/validate-api-curl.png)

### Resultado

- ✔ API de contas respondendo corretamente
- ✔ API de transações respondendo corretamente
- ✔ API de auditoria respondendo corretamente
- ✔ Endpoints de saúde retornando sucesso
- ✔ Aplicações permaneceram operacionais após a aplicação das configurações de segurança

### 9. Referência dos Manifestos Kubernetes

Manifestos utilizados nesta etapa:

- 📄 [01-mutate-security-context.yaml](../k8s/etapa-4.2/01-mutate-security-context.yaml)
- 📄 [02-nginx-teste.yaml](../k8s/etapa-4.2/02-nginx-teste.yaml)

### Conclusão

- ✔ ClusterPolicy `mutate-security-context` implementada com sucesso
- ✔ SecurityContext injetado automaticamente em novos Pods
- ✔ Execução non-root aplicada automaticamente
- ✔ Escalonamento de privilégios bloqueado
- ✔ Root filesystem protegido em modo somente leitura
- ✔ APIs do TipsBank permaneceram funcionais após a aplicação da política

---

