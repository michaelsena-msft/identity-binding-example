#!/bin/sh
set -eou pipefail
. $(dirname $(realpath $0))/.env

log -- Step 1: Creating AKS cluster
./01-create-aks.sh

log -- Step 2: Setting a secret in Key Vault
./02-secret.sh

log -- Step 3: Build the image
./03-deploy.sh

log -- Step 4: Apply the deployment
./04-planet.sh
