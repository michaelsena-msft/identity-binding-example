#!/bin/sh
set -eou pipefail

echo "## Step 1: Creating AKS cluster..."
./01-create-aks.sh

echo "## Step 2: Configuring web..."
./02-web.sh

echo "## Step 3: Deploying LoadBalancer service..."
./03-loadbalancer.sh

echo "## Step 4: Verifying deployment..."
./04-verify.sh