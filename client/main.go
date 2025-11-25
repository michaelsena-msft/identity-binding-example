package main

import (
	"context"
	"fmt"
	"log"
	"os"

	"github.com/Azure/azure-sdk-for-go/sdk/azcore/to"
	"github.com/Azure/azure-sdk-for-go/sdk/azidentity"
	"github.com/Azure/azure-sdk-for-go/sdk/resourcemanager/containerservice/armcontainerservice/v8"
)

type Parameters struct {
	SubscriptionID  string
	ResourceGroup   string
	ClusterName     string
	ManagedIdentity string
	BindingName     string
}

func main() {
	// This is a really quick & dirty demo of CRUD operations for identity bindings.
	parameters := Parameters{
		SubscriptionID:  os.Getenv("AZURE_SUBSCRIPTION_ID"),
		ResourceGroup:   os.Getenv("RESOURCE_GROUP"),
		ClusterName:     os.Getenv("CLUSTER_NAME"),
		ManagedIdentity: os.Getenv("MANAGED_IDENTITY"),
		BindingName:     os.Getenv("BINDING_NAME"),
	}
	cred, err := azidentity.NewDefaultAzureCredential(nil)
	if err != nil {
		log.Fatalf("failed to obtain a credential: %v", err)
	}

	ctx := context.Background()
	clientFactory, err := armcontainerservice.NewClientFactory(parameters.SubscriptionID, cred, nil)
	if err != nil {
		log.Fatalf("failed to create client: %v", err)
	}

	client := clientFactory.NewIdentityBindingsClient()

	if len(os.Args) != 2 {
		log.Fatalf("Run with either create, list or delete.")
	}

	switch os.Args[1] {
	case "create":
		fmt.Printf("Creating/Updating identity binding %s, targeting: %s\n", parameters.BindingName, parameters.ManagedIdentity)
		operation, err := client.BeginCreateOrUpdate(ctx, parameters.ResourceGroup, parameters.ClusterName, parameters.BindingName, armcontainerservice.IdentityBinding{
			Properties: &armcontainerservice.IdentityBindingProperties{
				ManagedIdentity: &armcontainerservice.IdentityBindingManagedIdentityProfile{
					ResourceID: to.Ptr(parameters.ManagedIdentity),
				},
			},
		}, nil)

		if err != nil {
			log.Fatalf("failed to finish the request: %v", err)
		}

		result, err := operation.PollUntilDone(ctx, nil)
		if err != nil {
			log.Fatalf("failed to pull the result: %v", err)
		}
		fmt.Printf("Identity Binding ID: %s\n", *result.ID)
	case "list":
		fmt.Println("Listing identity bindings")
		pager := client.NewListByManagedClusterPager(parameters.ResourceGroup, parameters.ClusterName, nil)
		for pager.More() {
			page, err := pager.NextPage(ctx)
			if err != nil {
				log.Fatalf("failed to advance page: %v", err)
			}
			for _, v := range page.Value {
				fmt.Printf("Identity: %s\n\tClient:\t\t%s\n\tIdentity:\t%s\n\tIssuer:\t\t%s\n", *v.Name, *v.Properties.ManagedIdentity.ClientID, *v.Properties.ManagedIdentity.ResourceID, *v.Properties.OidcIssuer.OidcIssuerURL)
			}
		}
	case "delete":
		fmt.Printf("Deleting identity binding %s\n", parameters.BindingName)
		operation, err := client.BeginDelete(ctx, parameters.ResourceGroup, parameters.ClusterName, parameters.BindingName, &armcontainerservice.IdentityBindingsClientBeginDeleteOptions{})

		if err != nil {
			log.Fatalf("failed to finish the request: %v", err)
		}

		_, err = operation.PollUntilDone(ctx, nil)
		if err != nil {
			log.Fatalf("failed to pull the result: %v", err)
		}
		fmt.Printf("Deleted Identity Binding ID: %s\n", parameters.BindingName)

	default:
		log.Fatalf("Unknown command: %s. Use either create or list.", os.Args[0])
	}
}
