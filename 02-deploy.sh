#!/bin/sh
set -eou pipefail
. $(dirname $(realpath $0))/.env

log Building identity-example image
TARGET=${ACR_FQDN}/identity-example:latest
podman build -t ${TARGET} app

log Pushing ${TARGET} to ACR
podman push ${TARGET}