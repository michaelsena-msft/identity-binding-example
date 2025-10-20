#!/bin/sh
set -eou pipefail
. ./.env

# Create the DNS Zone
#az network dns zone create -g ${RG} -n ${FQDN}

# Azure DNS example
#az network dns record-set cname set-record -g ${RG} -z ${LOC}.cloudapp.azure.com -n mars -c ${FQDN}
#az network dns record-set cname set-record -g ${RG} -z ${LOC}.cloudapp.azure.com -n jupiter -c ${FQDN}

# Apply ingress resource with DNS label substitution
echo "Creating ingress resource..."
envsubst < 06-ingress.yaml | kubectl apply -f -

# Wait for ingress to be configured
echo "Waiting for ingress to be configured..."
sleep 5

# Show ingress status
echo "Ingress status:"
kubectl get ingress -n web