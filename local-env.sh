#!/bin/sh
set -eou pipefail
. ./.env

az aks get-credentials -g "$RG" -n "$CLUSTER" --overwrite-existing
az acr login -g "$RG" -n "$ACR_NAME"