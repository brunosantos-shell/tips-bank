# Etapa 4.4 — RBAC com certificados X.509

## CSRs
```text
NAME                  AGE     SIGNERNAME                            REQUESTOR          REQUESTEDDURATION   CONDITION
auditor-global        7m31s   kubernetes.io/kube-apiserver-client   kubernetes-admin   365d                Approved,Issued
operador-contas       7m36s   kubernetes.io/kube-apiserver-client   kubernetes-admin   365d                Approved,Issued
operador-transacoes   7m33s   kubernetes.io/kube-apiserver-client   kubernetes-admin   365d                Approved,Issued
sre                   7m31s   kubernetes.io/kube-apiserver-client   kubernetes-admin   365d                Approved,Issued
```

## Roles e RoleBindings
```text
NAME                                                   CREATED AT
role.rbac.authorization.k8s.io/api-contas-pod-reader   2026-07-19T17:37:17Z
role.rbac.authorization.k8s.io/operador-contas         2026-07-19T17:36:18Z

NAME                                                          ROLE                         AGE
rolebinding.rbac.authorization.k8s.io/api-contas-pod-reader   Role/api-contas-pod-reader   17m
rolebinding.rbac.authorization.k8s.io/operador-contas         Role/operador-contas         18m
NAME                                                       CREATED AT
role.rbac.authorization.k8s.io/api-transacoes-pod-reader   2026-07-19T17:37:18Z
role.rbac.authorization.k8s.io/operador-transacoes         2026-07-19T17:36:18Z

NAME                                                              ROLE                             AGE
rolebinding.rbac.authorization.k8s.io/api-transacoes-pod-reader   Role/api-transacoes-pod-reader   17m
rolebinding.rbac.authorization.k8s.io/operador-transacoes         Role/operador-transacoes         18m
```

## ClusterRoles e ClusterRoleBindings
```text
NAME             CREATED AT
auditor-global   2026-07-19T17:36:34Z
NAME                ROLE                         AGE
auditor-global      ClusterRole/auditor-global   17m
sre-cluster-admin   ClusterRole/cluster-admin    17m
```

## ServiceAccounts
```text
NAME            AGE
sa-api-contas   17m
NAME                AGE
sa-api-transacoes   17m
```

## Operador contas — acesso permitido
```text
NAME                         READY   STATUS    RESTARTS      AGE
api-contas-f95565b95-2ctlw   1/1     Running   0             16m
api-contas-f95565b95-wt2s7   1/1     Running   0             16m
postgres-0                   1/1     Running   3 (27h ago)   57d
postgres-replica-0           1/1     Running   3 (27h ago)   57d
```

## Operador contas — acesso negado
```text
Error from server (Forbidden): pods is forbidden: User "operador-contas" cannot list resource "pods" in API group "" in the namespace "tipsbank-transacoes"
```

## Auditor — acesso global permitido
```text
NAMESPACE             NAME                                                        READY   STATUS                       RESTARTS         AGE
cert-manager          cert-manager-5957746d66-5nzrj                               1/1     Running                      5 (5h14m ago)    59d
cert-manager          cert-manager-cainjector-567c6b47ff-sv5qn                    1/1     Running                      5 (5h14m ago)    59d
cert-manager          cert-manager-webhook-7cc5c588cb-bbgnt                       1/1     Running                      4 (27h ago)      59d
default               nginx-mutate                                                0/1     CreateContainerConfigError   0                3h42m
ingress-nginx         ingress-nginx-controller-6c7cd85885-9qnnt                   1/1     Running                      3 (27h ago)      59d
ingress-nginx         ingress-nginx-controller-6c7cd85885-r7z8j                   1/1     Running                      3 (27h ago)      59d
kube-system           calico-kube-controllers-f8bc7b9cc-pgjns                     1/1     Running                      5 (5h14m ago)    62d
kube-system           calico-node-66m8f                                           1/1     Running                      3 (27h ago)      64d
kube-system           calico-node-n7bp5                                           1/1     Running                      5 (27h ago)      86d
kube-system           calico-node-q26nm                                           1/1     Running                      7 (27h ago)      86d
kube-system           coredns-7d764666f9-nhzcq                                    1/1     Running                      4 (27h ago)      86d
kube-system           coredns-7d764666f9-tn6n4                                    1/1     Running                      4 (27h ago)      86d
kube-system           etcd-master-k8s                                             1/1     Running                      4 (27h ago)      86d
kube-system           kube-apiserver-master-k8s                                   1/1     Running                      12 (5h14m ago)   86d
kube-system           kube-controller-manager-master-k8s                          1/1     Running                      47 (5h16m ago)   86d
kube-system           kube-proxy-8f9mg                                            1/1     Running                      3 (27h ago)      64d
kube-system           kube-proxy-czkm4                                            1/1     Running                      4 (27h ago)      86d
kube-system           kube-proxy-gmktn                                            1/1     Running                      5 (27h ago)      86d
kube-system           kube-scheduler-master-k8s                                   1/1     Running                      42 (5h16m ago)   86d
kube-system           metrics-server-b9b97c5b5-7n5n8                              1/1     Running                      5 (27h ago)      59d
kyverno               kyverno-admission-controller-7cdf5b9c-42n6f                 1/1     Running                      0                5h13m
kyverno               kyverno-background-controller-7b54965bf9-k9z7z              1/1     Running                      0                5h13m
kyverno               kyverno-cleanup-controller-59c8fdfb66-7bkp9                 1/1     Running                      0                5h13m
kyverno               kyverno-reports-controller-5c96886c9-vsq59                  1/1     Running                      0                5h13m
local-path-storage    local-path-provisioner-7d4d469b6-nlqdf                      1/1     Running                      3 (27h ago)      59d
metallb-system        controller-c8d7656df-fpvgb                                  1/1     Running                      3 (27h ago)      59d
metallb-system        speaker-9fkjk                                               1/1     Running                      8 (27h ago)      83d
metallb-system        speaker-d9ww7                                               1/1     Running                      15 (27h ago)     64d
metallb-system        speaker-lphl8                                               1/1     Running                      17 (27h ago)     83d
tigera-operator       tigera-operator-6cf4cccc57-zrvt4                            1/1     Running                      50 (5h15m ago)   86d
tipsbank-auditoria    auditoria-79448bc757-68cp4                                  1/1     Running                      2 (27h ago)      33d
tipsbank-auditoria    auditoria-79448bc757-ffwrb                                  1/1     Running                      2 (27h ago)      33d
tipsbank-contas       api-contas-f95565b95-2ctlw                                  1/1     Running                      0                16m
tipsbank-contas       api-contas-f95565b95-wt2s7                                  1/1     Running                      0                16m
tipsbank-contas       postgres-0                                                  1/1     Running                      3 (27h ago)      57d
tipsbank-contas       postgres-replica-0                                          1/1     Running                      3 (27h ago)      57d
tipsbank-monitoring   alertmanager-kube-prometheus-stack-alertmanager-0           2/2     Running                      6 (27h ago)      57d
tipsbank-monitoring   kube-prometheus-stack-grafana-788ff8544c-fk2q2              3/3     Running                      5 (5h14m ago)    22d
tipsbank-monitoring   kube-prometheus-stack-kube-state-metrics-5f54c8cf7d-z77s7   1/1     Running                      10 (5h13m ago)   59d
tipsbank-monitoring   kube-prometheus-stack-operator-59498456c9-ppdff             1/1     Running                      4 (27h ago)      59d
tipsbank-monitoring   kube-prometheus-stack-prometheus-node-exporter-4gcq6        1/1     Running                      3 (27h ago)      63d
tipsbank-monitoring   kube-prometheus-stack-prometheus-node-exporter-h62n9        1/1     Running                      11 (27h ago)     63d
tipsbank-monitoring   kube-prometheus-stack-prometheus-node-exporter-svpdd        1/1     Running                      6 (27h ago)      63d
tipsbank-monitoring   locust-79549c7c88-dns7d                                     1/1     Running                      1 (27h ago)      21d
tipsbank-monitoring   node-logger-42csr                                           1/1     Running                      3 (27h ago)      56d
tipsbank-monitoring   node-logger-x6kzj                                           1/1     Running                      3 (27h ago)      56d
tipsbank-monitoring   prometheus-kube-prometheus-stack-prometheus-0               2/2     Running                      9 (27h ago)      57d
tipsbank-transacoes   api-transacoes-6c685d4449-grj74                             2/2     Running                      2 (27h ago)      21d
tipsbank-transacoes   api-transacoes-6c685d4449-mdc5w                             2/2     Running                      3 (27h ago)      21d
tipsbank-transacoes   api-transacoes-6c685d4449-s7qj8                             2/2     Running                      2 (27h ago)      21d
tipsbank-transacoes   api-transacoes-75cdf8cf79-kwmgj                             1/2     CreateContainerConfigError   0                14m
tipsbank-transacoes   api-transacoes-v2-7ccf7cf549-92d7x                          2/2     Running                      6 (27h ago)      59d
tipsbank-transacoes   api-transacoes-v2-7ccf7cf549-wtf6q                          2/2     Running                      6 (27h ago)      59d
tipsbank-transacoes   api-transacoes-v2-7dfd64fdd9-69nl4                          1/2     CreateContainerConfigError   0                16m
tipsbank-web          web-bdf555c5c-7b7wp                                         1/1     Running                      1 (27h ago)      21d
tipsbank-web          web-bdf555c5c-hf8gs                                         1/1     Running                      1 (27h ago)      21d
```

## Auditor — exclusão negada
```text
Error from server (Forbidden): pods "api-contas-f95565b95-2ctlw" is forbidden: User "auditor-global" cannot delete resource "pods" in API group "" in the namespace "tipsbank-contas"
```

## Operador transações — exec permitido
```text
no
```

## SRE — cluster-admin
```text
yes
```
