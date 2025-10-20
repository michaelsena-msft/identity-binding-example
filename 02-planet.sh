#!/bin/sh
set -eou pipefail
. ./.env

k apply -f 02-planet.yaml

k -n web rollout status deploy/planet --timeout=120s
k -n web get pods -l app=planet -o wide
