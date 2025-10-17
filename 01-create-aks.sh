#!/bin/sh
set -eou pipefail
. ./.env

az group create -n "$RG" -l "$LOC"

az aks create \
  -g "$RG" -n "$CLUSTER" \
  --location "$LOC" \
  --enable-managed-identity \
  --node-count 1 \
  --node-vm-size Standard_B2s

# Verify
az aks show -g "$RG" -n "$CLUSTER" --query "provisioningState" -o tsv | grep -x Succeeded

# Configure kubeconfig
az aks get-credentials -g "$RG" -n "$CLUSTER" --overwrite-existing

# Verify cluster reachable
k get nodes -o wide
