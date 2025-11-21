#!/bin/sh
set -eou pipefail
. $(dirname $(realpath $0))/.env

info Verifying OIDC Container
if ! k logs -l app=planet -c oidc | tail -1 | grep 'success' > /dev/null; then
    echo "OIDC authentication failed for oidc container" >&2
    exit 1
fi

info Verifying our Application
if ! k logs -l app=planet -c identity-example | tail -2 | grep 'Retrieved secret' > /dev/null; then
    echo "OIDC authentication failed for our application" >&2
    exit 1
fi
