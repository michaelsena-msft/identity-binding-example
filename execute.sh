#!/bin/sh
set -eou pipefail
[ -f ./.env ] && . ./.env || . ../.env

log -- Step 1: Creating AKS cluster
./01-create-aks.sh

log -- Step 2: Configuring the generic planet
./02-planet.sh

log -- Step 3: Deploying Mars service
./03-mars.sh

log -- Step 4: Deploying Jupiter service
./04-jupiter.sh

log -- Step 5: Installing Ingress Controller
./05-install-ingress-nginx.sh

log -- Step 6: Configuring Ingress routes
./06-configure-ingress.sh

log -- Step 7: Replace the image with our own
./07-replace-image.sh

LOG -- Step 8: Use the Dalec image instead
./08-use-dalec.sh