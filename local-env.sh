#!/bin/sh
set -eou pipefail
. $(dirname $(realpath $0))/.env

log Retrieving cluster credentials for kubectl
az aks get-credentials -g "$RESOURCE_GROUP" -n "$CLUSTER" --overwrite-existing

log Logging into ACR
DOCKER_COMMAND=podman az acr login -g "$RESOURCE_GROUP" -n "$ACR_NAME"

if ! command helm > /dev/null 2>&1; then
  echo Helm not found >&2
fi