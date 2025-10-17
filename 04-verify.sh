#!/bin/sh
set -eou pipefail
. ./.env

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
