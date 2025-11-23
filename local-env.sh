#!/bin/sh
set -eou pipefail
. $(dirname $(realpath $0))/.env

log Retrieving cluster credentials for kubectl
az aks get-credentials -g "$RESOURCE_GROUP" -n "$CLUSTER" --overwrite-existing

log Logging into ACR
DOCKER_COMMAND=podman az acr login -g "$RESOURCE_GROUP" -n "$ACR_NAME" --only-show-errors

log Verifying required tools are installed
if ! which jq > /dev/null; then
  echo "jq is not installed" >&2
  exit 1
fi