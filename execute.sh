#!/bin/sh
set -eou pipefail
. $(dirname $(realpath $0))/.env

log -- Step 1: Creating AKS cluster
./01-create-aks.sh

log -- Step 2: Build the image
./02-deploy.sh

log -- Step 3: Apply the deployment
./03-planet.sh