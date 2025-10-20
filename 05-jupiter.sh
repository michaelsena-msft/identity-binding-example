#!/bin/sh
set -eou pipefail
. ./.env

k apply -f 05-jupiter.yaml

k -n web rollout status deploy/jupiter --timeout=120s
k -n web get pods -l app=jupiter -o wide