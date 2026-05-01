#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="k8s/etapa-1.4"

mkdir -p "$BASE_DIR"

cat > "$BASE_DIR/00-namespaces.yaml" <<'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: tipsbank-contas
---
apiVersion: v1
kind: Namespace
metadata:
  name: tipsbank-transacoes
---
apiVersion: v1
kind: Namespace
metadata:
  name: tipsbank-auditoria
---
apiVersion: v1
kind: Namespace
metadata:
  name: tipsbank-web
EOF

cat > "$BASE_DIR/01-registry-secret.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

REGISTRY_SERVER="${REGISTRY_SERVER:-ghcr.io}"
REGISTRY_USER="${REGISTRY_USER:-SEU_USUARIO}"
REGISTRY_TOKEN="${REGISTRY_TOKEN:-SEU_TOKEN}"
REGISTRY_EMAIL="${REGISTRY_EMAIL:-seu-email@dominio.com}"

for NS in tipsbank-contas tipsbank-transacoes tipsbank-auditoria tipsbank-web; do
  kubectl create secret docker-registry registry-secret \
    --docker-server="$REGISTRY_SERVER" \
    --docker-username="$REGISTRY_USER" \
    --docker-password="$REGISTRY_TOKEN" \
    --docker-email="$REGISTRY_EMAIL" \
    -n "$NS" \
    --dry-run=client -o yaml | kubectl apply -f -
done
EOF

chmod +x "$BASE_DIR/01-registry-secret.sh"

cat > "$BASE_DIR/02-secret-db.yaml" <<'EOF'
apiVersion: v1
kind: Secret
metadata:
  name: secret-db
  namespace: tipsbank-contas
type: Opaque
stringData:
  POSTGRES_DB: tipsbank
  POSTGRES_USER: tipsbank
  POSTGRES_PASSWORD: TipsBank@123
EOF

cat > "$BASE_DIR/03-configmap-app.yaml" <<'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: configmap-app
  namespace: tipsbank-contas
data:
  API_CONTAS_URL: "http://api-contas.tipsbank-contas.svc.cluster.local:8080"
  API_TRANSACOES_URL: "http://api-transacoes.tipsbank-transacoes.svc.cluster.local:8080"
  API_AUDITORIA_URL: "http://auditoria.tipsbank-auditoria.svc.cluster.local:8080"
  POSTGRES_HOST: "postgres-0.postgres-headless.tipsbank-contas.svc.cluster.local"
  POSTGRES_PORT: "5432"
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: configmap-app
  namespace: tipsbank-transacoes
data:
  API_CONTAS_URL: "http://api-contas.tipsbank-contas.svc.cluster.local:8080"
  API_AUDITORIA_URL: "http://auditoria.tipsbank-auditoria.svc.cluster.local:8080"
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: configmap-app
  namespace: tipsbank-auditoria
data:
  API_CONTAS_URL: "http://api-contas.tipsbank-contas.svc.cluster.local:8080"
  API_TRANSACOES_URL: "http://api-transacoes.tipsbank-transacoes.svc.cluster.local:8080"
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: configmap-app
  namespace: tipsbank-web
data:
  API_CONTAS_URL: "http://api-contas.tipsbank-contas.svc.cluster.local:8080"
  API_TRANSACOES_URL: "http://api-transacoes.tipsbank-transacoes.svc.cluster.local:8080"
  API_AUDITORIA_URL: "http://auditoria.tipsbank-auditoria.svc.cluster.local:8080"
EOF

cat > "$BASE_DIR/04-postgres.yaml" <<'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: postgres-init-sql
  namespace: tipsbank-contas
data:
  init.sql: |
    CREATE TABLE IF NOT EXISTS contas (
      id SERIAL PRIMARY KEY,
      nome VARCHAR(100) NOT NULL,
      email VARCHAR(150) UNIQUE NOT NULL,
      senha_hash TEXT NOT NULL,
      saldo NUMERIC(12,2) DEFAULT 0
    );

    INSERT INTO contas (nome, email, senha_hash, saldo)
    VALUES
      ('Cliente Um', 'cliente1@tipsbank.local', '$2b$12$hashprecomputado1', 1000.00),
      ('Cliente Dois', 'cliente2@tipsbank.local', '$2b$12$hashprecomputado2', 1500.00)
    ON CONFLICT (email) DO NOTHING;
---
apiVersion: v1
kind: Service
metadata:
  name: postgres-headless
  namespace: tipsbank-contas
spec:
  clusterIP: None
  selector:
    app: postgres
  ports:
    - name: postgres
      port: 5432
      targetPort: 5432
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
  namespace: tipsbank-contas
spec:
  serviceName: postgres-headless
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      imagePullSecrets:
        - name: registry-secret
      containers:
        - name: postgres
          image: postgres:16
          ports:
            - containerPort: 5432
          envFrom:
            - secretRef:
                name: secret-db
          volumeMounts:
            - name: postgres-data
              mountPath: /var/lib/postgresql/data
            - name: init-sql
              mountPath: /docker-entrypoint-initdb.d/
      volumes:
        - name: init-sql
          configMap:
            name: postgres-init-sql
  volumeClaimTemplates:
    - metadata:
        name: postgres-data
      spec:
        accessModes:
          - ReadWriteOnce
        resources:
          requests:
            storage: 2Gi
EOF

cat > criar-manifestos-apps.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="${BASE_DIR:-.}"
REGISTRY="${REGISTRY:-ghcr.io/seu-usuario}"
TAG="${TAG:-v1.0.0}"

mkdir -p "$BASE_DIR"

cat > "$BASE_DIR/05-api-contas.yaml" <<EOF_API_CONTAS
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-contas
  namespace: tipsbank-contas
spec:
  replicas: 2
  selector:
    matchLabels:
      app: api-contas
  template:
    metadata:
      labels:
        app: api-contas
    spec:
      imagePullSecrets:
        - name: registry-secret
      containers:
        - name: api-contas
          image: ${REGISTRY}/api-contas:${TAG}
          ports:
            - containerPort: 8080
          envFrom:
            - configMapRef:
                name: configmap-app
            - secretRef:
                name: secret-db
---
apiVersion: v1
kind: Service
metadata:
  name: api-contas
  namespace: tipsbank-contas
spec:
  type: ClusterIP
  selector:
    app: api-contas
  ports:
    - port: 8080
      targetPort: 8080
EOF_API_CONTAS

cat > "$BASE_DIR/06-api-transacoes.yaml" <<EOF_API_TRANSACOES
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-transacoes
  namespace: tipsbank-transacoes
spec:
  replicas: 2
  selector:
    matchLabels:
      app: api-transacoes
  template:
    metadata:
      labels:
        app: api-transacoes
    spec:
      imagePullSecrets:
        - name: registry-secret
      containers:
        - name: api-transacoes
          image: ${REGISTRY}/api-transacoes:${TAG}
          ports:
            - containerPort: 8080
          envFrom:
            - configMapRef:
                name: configmap-app
---
apiVersion: v1
kind: Service
metadata:
  name: api-transacoes
  namespace: tipsbank-transacoes
spec:
  type: ClusterIP
  selector:
    app: api-transacoes
  ports:
    - port: 8080
      targetPort: 8080
EOF_API_TRANSACOES

cat > "$BASE_DIR/07-auditoria.yaml" <<EOF_AUDITORIA
apiVersion: apps/v1
kind: Deployment
metadata:
  name: auditoria
  namespace: tipsbank-auditoria
spec:
  replicas: 2
  selector:
    matchLabels:
      app: auditoria
  template:
    metadata:
      labels:
        app: auditoria
    spec:
      imagePullSecrets:
        - name: registry-secret
      containers:
        - name: auditoria
          image: ${REGISTRY}/auditoria:${TAG}
          ports:
            - containerPort: 8080
          envFrom:
            - configMapRef:
                name: configmap-app
          volumeMounts:
            - name: auditoria-data
              mountPath: /data
      volumes:
        - name: auditoria-data
          emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: auditoria
  namespace: tipsbank-auditoria
spec:
  type: ClusterIP
  selector:
    app: auditoria
  ports:
    - port: 8080
      targetPort: 8080
EOF_AUDITORIA

cat > "$BASE_DIR/08-web.yaml" <<EOF_WEB
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-conf
  namespace: tipsbank-web
data:
  nginx.conf: |
    events {}

    http {
      upstream api_contas {
        server api-contas.tipsbank-contas.svc.cluster.local:8080;
      }

      upstream api_transacoes {
        server api-transacoes.tipsbank-transacoes.svc.cluster.local:8080;
      }

      upstream auditoria {
        server auditoria.tipsbank-auditoria.svc.cluster.local:8080;
      }

      server {
        listen 80;

        location / {
          root /usr/share/nginx/html;
          index index.html;
          try_files \$uri /index.html;
        }

        location /api/contas/ {
          proxy_pass http://api_contas/;
        }

        location /api/transacoes/ {
          proxy_pass http://api_transacoes/;
        }

        location /api/auditoria/ {
          proxy_pass http://auditoria/;
        }
      }
    }
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
  namespace: tipsbank-web
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      imagePullSecrets:
        - name: registry-secret
      containers:
        - name: web
          image: ${REGISTRY}/web:${TAG}
          ports:
            - containerPort: 80
          volumeMounts:
            - name: nginx-conf
              mountPath: /etc/nginx/nginx.conf
              subPath: nginx.conf
      volumes:
        - name: nginx-conf
          configMap:
            name: nginx-conf
---
apiVersion: v1
kind: Service
metadata:
  name: web
  namespace: tipsbank-web
spec:
  type: ClusterIP
  selector:
    app: web
  ports:
    - port: 8080
      targetPort: 80
EOF_WEB

echo "Manifestos criados em: $BASE_DIR"
ls -lh "$BASE_DIR"/05-api-contas.yaml "$BASE_DIR"/06-api-transacoes.yaml "$BASE_DIR"/07-auditoria.yaml "$BASE_DIR"/08-web.yaml
EOF

chmod +x criar-manifestos-apps.sh