#!/bin/sh
set -eou pipefail
. ./.env

echo "=== Verifying Ingress Endpoints ==="
echo ""

# Test 1: Default nginx endpoint (base FQDN)
echo "1. Testing default nginx endpoint: http://${DNS_LABEL}.australiaeast.cloudapp.azure.com/"
echo "   Expected: Should show nginx pods"
SAMPLE_FILE_NGINX="$(mktemp)"
for i in $(seq 1 10); do
  curl -fsS "http://${DNS_LABEL}.australiaeast.cloudapp.azure.com/" | awk -F'</?p>' '/Pod:/{gsub(/^[ \t]+|[ \t]+$/,"",$2); print $2}' >> "$SAMPLE_FILE_NGINX"
done
echo "   Observed pods:"
sort "$SAMPLE_FILE_NGINX" | uniq -c | sed 's/^/   /'
rm "$SAMPLE_FILE_NGINX"
echo "   ✓ Default nginx endpoint responding"
echo ""

# Test 2: Mars service endpoint
echo "2. Testing Mars endpoint: http://${DNS_LABEL}.australiaeast.cloudapp.azure.com/mars"
echo "   Expected: Should show Mars pod"
SAMPLE_FILE_MARS="$(mktemp)"
for i in $(seq 1 5); do
  curl -fsS "http://${DNS_LABEL}.australiaeast.cloudapp.azure.com/mars" | awk -F'</?p>' '/Pod:/{gsub(/^[ \t]+|[ \t]+$/,"",$2); print $2}' >> "$SAMPLE_FILE_MARS"
done
echo "   Observed pods:"
sort "$SAMPLE_FILE_MARS" | uniq -c | sed 's/^/   /'
# Verify it's actually a Mars pod
if ! grep -q "mars" "$SAMPLE_FILE_MARS"; then
  echo "   ✗ ERROR: Expected Mars pod, but got other pods"
  rm "$SAMPLE_FILE_MARS"
  exit 1
fi
rm "$SAMPLE_FILE_MARS"
echo "   ✓ Mars endpoint routing correctly"
echo ""

# Test 3: Jupiter service endpoint
echo "3. Testing Jupiter endpoint: http://${DNS_LABEL}.australiaeast.cloudapp.azure.com/jupiter"
echo "   Expected: Should show Jupiter pod"
SAMPLE_FILE_JUPITER="$(mktemp)"
for i in $(seq 1 5); do
  curl -fsS "http://${DNS_LABEL}.australiaeast.cloudapp.azure.com/jupiter" | awk -F'</?p>' '/Pod:/{gsub(/^[ \t]+|[ \t]+$/,"",$2); print $2}' >> "$SAMPLE_FILE_JUPITER"
done
echo "   Observed pods:"
sort "$SAMPLE_FILE_JUPITER" | uniq -c | sed 's/^/   /'
# Verify it's actually a Jupiter pod
if ! grep -q "jupiter" "$SAMPLE_FILE_JUPITER"; then
  echo "   ✗ ERROR: Expected Jupiter pod, but got other pods"
  rm "$SAMPLE_FILE_JUPITER"
  exit 1
fi
rm "$SAMPLE_FILE_JUPITER"
echo "   ✓ Jupiter endpoint routing correctly"
echo ""

echo "=== All Ingress Endpoints Verified Successfully ==="
echo ""
echo "Summary:"
echo "  • Default:  http://${DNS_LABEL}.australiaeast.cloudapp.azure.com/ → nginx pods"
echo "  • Mars:     http://${DNS_LABEL}.australiaeast.cloudapp.azure.com/mars → mars pod"
echo "  • Jupiter:  http://${DNS_LABEL}.australiaeast.cloudapp.azure.com/jupiter → jupiter pod"