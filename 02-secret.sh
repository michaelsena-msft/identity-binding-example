#!/bin/sh
set -eou pipefail
. $(dirname $(realpath $0))/.env

log Set a secret to verify role assignments.

az keyvault secret set \
  --vault-name ${KEY_VAULT} \
  --name ${SECRET_NAME} \
  --value "ThisIsSuperDuperSecret" \
  --only-show-errors \
  -o table