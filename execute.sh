#!/bin/sh
set -eou pipefail
. $(dirname $(realpath $0))/.env

log -- Step 1: Creating AKS cluster
./01-create-aks.sh

log -- Step 2: Setting a secret in Key Vault
./02-secret.sh

log -- Step 3: Build the image
./03-deploy.sh

log -- Step 4: Add a deployment showing workload identity
./04-wi.sh

log -- Step 5: Add a deployment showing identity binding
./05-ib.sh

log -- All steps completed successfully
