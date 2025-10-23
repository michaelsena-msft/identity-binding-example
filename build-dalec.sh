#!/bin/sh
set -eou pipefail

cd ../dalec
docker build -t ingress-nginx-alt:v1.13.3 -f specs/ingress-nginx/controller-1.13.3.yml --target azlinux3/container .
#docker build -t nginx-ingress-dalec:v5.2.1 -f specs/nginx-ingress/nginx-ingress-5.2.1.yml --target azlinux3/container .

# To testing locally:
# docker run -i --rm -e ingress-nginx-alt:v1.13.3
