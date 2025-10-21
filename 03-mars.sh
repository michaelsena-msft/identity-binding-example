#!/bin/sh
set -eou pipefail
[ -f ./.env ] && . ./.env || . ../.env

k apply -f 03-mars.yaml

k -n web rollout status deploy/mars --timeout=120s
k -n web get pods -l app=mars -o wide