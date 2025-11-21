#!/bin/sh
set -eou pipefail
. $(dirname $(realpath $0))/.env

# Local kubeconfig cleanup (optional)
k config delete-context "$CLUSTER" || true
k config delete-cluster "$CLUSTER" || true
k config unset "users.clusterUser_${RESOURCE_GROUP}_${CLUSTER}" || true

# Add --no-wait if you really want.
az group delete -n "$RESOURCE_GROUP" --yes $@