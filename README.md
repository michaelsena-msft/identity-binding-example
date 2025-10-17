# Basic AKS Cluster with NGINX Example

## Instructions

1. Create a copy of `.env.sample` and name it `.env`.
1. Fill in the required values.
1. Run the scripts in order:
   - `01-create-aks.sh`
   - `02-kubeconfig.sh`
   - `03-deploy-app.sh`
   - `04-cleanup.sh` (when you want to delete the resources)