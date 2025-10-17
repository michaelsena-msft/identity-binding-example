#!/bin/sh
set -eou pipefail
. ./.env

cat <<'YAML' | k apply -n web -f -
apiVersion: v1
kind: Namespace
metadata:
  name: web
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  replicas: 3
  selector: { matchLabels: { app: nginx } }
  template:
    metadata:
      labels: { app: nginx }
    spec:
      containers:
        - name: nginx
          image: nginx:stable
          env:
            - name: POD_NAME
              valueFrom: { fieldRef: { fieldPath: metadata.name } }
            - name: POD_IP
              valueFrom: { fieldRef: { fieldPath: status.podIP } }
          ports:
            - containerPort: 80
          readinessProbe:
            httpGet: { path: "/", port: 80 }
            initialDelaySeconds: 3
            periodSeconds: 5
          livenessProbe:
            httpGet: { path: "/", port: 80 }
            initialDelaySeconds: 10
            periodSeconds: 10
          command: ["/bin/sh","-c"]
          args:
            - |
              cat >/usr/share/nginx/html/index.html <<EOF
              <!doctype html>
              <html>
                <head><meta charset="utf-8"><title>AKS NGINX</title></head>
                <body>
                  <h1>Hello from AKS (Again)</h1>
                  <p>Pod: ${POD_NAME}</p>
                  <p>IP: ${POD_IP}</p>
                  <p>Time: $(date -Iseconds)</p>
                </body>
              </html>
              EOF
              nginx -g 'daemon off;'
YAML

k -n web rollout status deploy/nginx --timeout=120s
k -n web get pods -l app=nginx -o wide
