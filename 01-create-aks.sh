#!/bin/sh
set -eou pipefail
[ -f ./.env ] && . ./.env || . ../.env

log Creating the resource group...
az group create -n "$RESOURCE_GROUP" -l "$REGION"

log Creating the ACR...
az acr create --admin-enabled true --sku standard -g "$RESOURCE_GROUP" -l "$REGION" -n "$ACR_NAME"

log Creating the cluster...
az aks create \
  -g "$RESOURCE_GROUP" -n "$CLUSTER" \
  --location "$REGION" \
  --enable-managed-identity \
  --node-count 1 \
  --node-vm-size Standard_D4s_v3 \
  --attach-acr $ACR_NAME

# Setup environment.
./local-env.sh

# Verify cluster reachable
k get nodes -o wide
