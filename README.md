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

## Go: app

In the `app` directory is a simple Go application that uses the Azure SDK to verify whether workload identity / identity bindings are working.

## Go: client

In the `client` directory is a simple Go application that can create, list or delete identity bindings.
Parameters are provided via environment variables, specified in the `main.go` file.

This was based off an [Azure SDK Example](https://github.com/Azure/azure-sdk-for-go/blob/main/sdk/resourcemanager/containerservice/armcontainerservice/identitybindings_client_example_test.go) for identity bindings.
