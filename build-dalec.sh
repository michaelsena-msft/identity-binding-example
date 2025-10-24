#!/bin/sh
set -eou pipefail
. $(dirname $(realpath $0))/.env
cd ${DALEC_DIR}
docker build -t ingress-nginx-alt:v1.13.3 -f specs/ingress-nginx/controller-1.13.3.yml --target azlinux3/container .
