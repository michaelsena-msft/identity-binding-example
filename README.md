# Basic AKS Cluster with NGINX Example

## Preparation

```shell
cp .env.user.sample .env.user
vi .env.user
```

## Usage:

```shell
execute.sh
```

## Environment Reconfiguration

To re-configure the local environment (e.g., `kubectl`) by running:

```sh
./local-env.sh
```

## Validation Commands

Before running, execute:

```shell
source .env
```

| Area | Task | Command |
| - | - | - |
| Ingress NGINX | Docker Image SHA | `docker image inspect ${ACR_NAME}.azurecr.io/ingress-nginx-alt:v1.13.3 | jq -r '.[].Id'` |
| Ingress NGINX | Deployment Image | `k get deployment ingress-nginx-controller -n ingress-nginx -o json | jq -r '.spec.template.spec.containers.[0].image' ` |
| Ingress NGINX | Currently running Image SHA | `k describe pods -n ingress-nginx | grep -e 'Image.\+:\w\w'` |
| Ingress NGINX | Current pod | `k get pods -n ingress-nginx --no-headers | awk '{print $1}'` |
| Ingress NGINX | log of current pod | `k logs -n ingress-nginx $(k get pods -n ingress-nginx --no-headers | awk '{print $1}')` |
| Ingress NGINX | Edit deployment | `k edit deployment ingress-nginx-controller -n ingress-nginx` |
