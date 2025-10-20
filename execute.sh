#!/bin/sh
set -eou pipefail

echo "## Step 1: Creating AKS cluster..."
./01-create-aks.sh

echo "## Step 2: Configuring the generic planet..."
./02-planet.sh

echo "## Step 3: Deploying Mars service..."
./03-mars.sh

echo "## Step 4: Deploying Jupiter service..."
./04-jupiter.sh

echo "## Step 5: Installing Ingress Controller..."
./05-install-ingress.sh

echo "## Step 6: Configuring Ingress routes..."
./06-configure-ingress.sh

echo "## Step 7: Verifying Ingress endpoints..."
./07-verify-ingress.sh