#!/bin/sh
set -eou pipefail
[ -f ./.env ] && . ./.env || . ../.env

log Retrieving cluster credentials for kubectl...
az aks get-credentials -g "$RESOURCE_GROUP" -n "$CLUSTER" --overwrite-existing

log Logging into ACR...
az acr login -g "$RESOURCE_GROUP" -n "$ACR_NAME"