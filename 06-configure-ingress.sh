#!/bin/sh
set -eou pipefail
[ -f ./.env ] && . ./.env || . ../.env

log Creating ingress resource
envsubst < 06-ingress-nginx.yaml | kubectl apply -f -

log Sleeping to allow Ingress to be configured
sleep 5

./operations/verify.sh