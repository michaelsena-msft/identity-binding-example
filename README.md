# Identity Bindings Example

Creates a set of Azure resources to demonstrate workload identity, and the new identity bindings.

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
