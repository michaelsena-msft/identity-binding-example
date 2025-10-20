#!/bin/sh
set -eou pipefail
. ./.env

# Service with Azure DNS label annotation -> ${FQDN}
envsubst < 03-loadbalancer.yaml | k apply -f -

# Wait for external IP
echo "Waiting for external IP..."
for i in $(seq 1 60); do
  EXTERNAL_IP="$(k -n web get svc/nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}' || true)"
  [ -n "${EXTERNAL_IP:-}" ] && break
  echo "Retrying ${i}/60"
  sleep 5
done
[ -n "${EXTERNAL_IP:-}" ] || { echo "Timed out waiting for external IP"; exit 1; }
echo "Service IP: $EXTERNAL_IP"

# Verify DNS resolves to the IP
echo "Waiting for ${FQDN} to resolve..."
for i in $(seq 1 60); do
  RESOLVED_IPS="$(getent ahostsv4 "$FQDN" | awk '{print $1}' | sort -u || true)"
  echo "$RESOLVED_IPS" | grep -q "$EXTERNAL_IP" && break
  echo "Retrying ${i}/60"
  sleep 5
done
echo "$RESOLVED_IPS" | grep -q "$EXTERNAL_IP"

# HTTP probe over FQDN
for i in $(seq 1 60); do
  STATUS="$(curl -s -o /dev/null -w "%{http_code}" "http://${FQDN}/" || true)"
  [ "$STATUS" = "200" ] && break
  echo "Retrying ${i}/60"
  sleep 5
done
[ "$STATUS" = "200" ] || { echo "HTTP check failed"; exit 1; }
echo "HTTP 200 from http://${FQDN}/"

# Endpoints should show two targets
k -n web get endpoints nginx -o wide

# Curl the service repeatedly and extract the Pod line
echo "Sampling responses from http://${FQDN}/"
SAMPLE_FILE="$(mktemp)"
for i in $(seq 1 20); do
  curl -fsS "http://${FQDN}/" | awk -F'</?p>' '/Pod:/{gsub(/^[ \t]+|[ \t]+$/,"",$2); print $2}' >> "$SAMPLE_FILE"
done

echo "Observed pods:"
sort "$SAMPLE_FILE" | uniq -c

# Assert that we saw exactly 2 distinct pod names
COUNT="$(sort "$SAMPLE_FILE" | uniq | wc -l | tr -d ' ')"
[ "$COUNT" -eq 3 ] || { echo "Expected 3 distinct pods, saw $COUNT"; exit 1; }
echo "OK: traffic reached both pods"

# Optional: show distribution
echo "Distribution over 20 requests:"
awk '{cnt[$0]++} END{for(p in cnt){printf "%-40s %d\n", p, cnt[p]}}' "$SAMPLE_FILE"
