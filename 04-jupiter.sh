#!/bin/sh
set -eou pipefail
[ -f ./.env ] && . ./.env || . ../.env

k apply -f 04-jupiter.yaml

k -n web rollout status deploy/jupiter --timeout=120s
k -n web get pods -l app=jupiter -o wide