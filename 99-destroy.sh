#!/bin/sh
set -eou pipefail
[ -f ./.env ] && . ./.env || . ../.env

az group delete -n "$RG" --yes --no-wait

# Local kubeconfig cleanup (optional)
k config delete-context "$CLUSTER" || true
k config delete-cluster "$CLUSTER" || true
k config unset "users.clusterUser_${RG}_${CLUSTER}" || true
