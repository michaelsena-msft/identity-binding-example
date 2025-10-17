#!/bin/sh
set -eou pipefail
. ./.env

# Service with Azure DNS label annotation -> ${FQDN}
cat <<YAML | k apply -n web -f -
apiVersion: v1
kind: Service
metadata:
  name: nginx
  annotations:
    service.beta.kubernetes.io/azure-dns-label-name: "${DNS_LABEL}"
spec:
  type: LoadBalancer
  selector:
    app: nginx
  ports:
    - name: http
      port: 80
      targetPort: 80
YAML

# Wait for external IP
echo "Waiting for external IP..."
for i in $(seq 1 60); do
  EXTERNAL_IP="$(k -n web get svc/nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}' || true)"
  [ -n "${EXTERNAL_IP:-}" ] && break
  sleep 5
done
[ -n "${EXTERNAL_IP:-}" ] || { echo "Timed out waiting for external IP"; exit 1; }
echo "Service IP: $EXTERNAL_IP"

# Verify DNS resolves to the IP
echo "Waiting for ${FQDN} to resolve..."
for i in $(seq 1 60); do
  RESOLVED_IPS="$(getent ahostsv4 "$FQDN" | awk '{print $1}' | sort -u || true)"
  echo "$RESOLVED_IPS" | grep -q "$EXTERNAL_IP" && break
  sleep 5
done
echo "$RESOLVED_IPS" | grep -q "$EXTERNAL_IP"

# HTTP probe over FQDN
for i in $(seq 1 60); do
  STATUS="$(curl -s -o /dev/null -w "%{http_code}" "http://${FQDN}/" || true)"
  [ "$STATUS" = "200" ] && break
  sleep 5
done
[ "$STATUS" = "200" ] || { echo "HTTP check failed"; exit 1; }
echo "HTTP 200 from http://${FQDN}/"
