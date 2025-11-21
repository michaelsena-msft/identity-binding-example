# Basic AKS Cluster that creates a Workload Identity

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

## Ingress NGINX Parameters

To see all possible overrides:

```shell
helm show values ingress-nginx --repo https://kubernetes.github.io/ingress-nginx
```
