package main

import (
	"context"
	"fmt"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/Azure/azure-sdk-for-go/sdk/azidentity"
	"github.com/Azure/azure-sdk-for-go/sdk/security/keyvault/azsecrets"
	"k8s.io/klog/v2"
)

type Credentials struct {
	keyVaultUrl string
	secretName  string
}

func main() {
	// Check key vault has been specified.
	credentials := Credentials{
		keyVaultUrl: os.Getenv("KEY_VAULT_URL"),
		secretName:  os.Getenv("SECRET_NAME"),
	}

	if credentials.keyVaultUrl == "" || credentials.secretName == "" {
		panic("KEY_VAULT_URL and SECRET_NAME environment variables must be set")
	}

	// Check if there is a custom interval set.
	interval := os.Getenv("INTERVAL")
	if interval == "" {
		interval = "5m"
	}
	duration, err := time.ParseDuration(interval)
	if err != nil {
		klog.ErrorS(err, "Invalid interval duration: %s", interval)
		os.Exit(1)
	}

	klog.InfoS("Starting main loop.", "interval", duration)
	check(credentials)

	sigCh := make(chan os.Signal, 1)
	signal.Notify(sigCh, os.Interrupt, syscall.SIGTERM)

	done := make(chan struct{})

	go func() {
		ticker := time.NewTicker(duration)
		defer ticker.Stop()
		for {
			select {
			case <-done:
				return
			case <-ticker.C:
				check(credentials)
			}
		}
	}()

	<-sigCh
	close(done)

	fmt.Printf("Ending application.")

}

func check(credentials Credentials) {
	klog.Info("Looking up our secret value.")

	credential, err := azidentity.NewDefaultAzureCredential(nil)
	if err != nil {
		klog.ErrorS(err, "Failed to obtain a credential.")
		return
	}

	client, err := azsecrets.NewClient(credentials.keyVaultUrl, credential, nil)
	if err != nil {
		klog.ErrorS(err, "Failed to create secret client")
		return
	}

	secret, err := client.GetSecret(context.Background(), credentials.secretName, "", nil)
	if err != nil {
		klog.ErrorS(err, "Failed to get secret")
		return
	}

	klog.InfoS("Retrieved secret", "secret", *secret.Value)
}
