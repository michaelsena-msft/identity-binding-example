#!/bin/sh
set -eou pipefail
[ -f ./.env ] && . ./.env || . ../.env

# Local kubeconfig cleanup (optional)
k config delete-context "$CLUSTER" || true
k config delete-cluster "$CLUSTER" || true
k config unset "users.clusterUser_${RG}_${CLUSTER}" || true

# Docker ACR clean-up.
docker logout ${ACR_FQDN}

# Add --no-wait if you really want.
az group delete -n "$RG" --yes $@