// credhub_setup is a command used to set up CF application security groups so
// that applications can communicate with the internal CredHub endpoint, as well
// as UAA if appropriate.
package main

import (
	"context"
	"fmt"
	"net/url"
	"os"

	"credhub_setup/cc"
	"credhub_setup/uaa"
)

func process(ctx context.Context) error {
	ctx, cancelFunc := context.WithCancel(ctx)
	defer cancelFunc()

	err := setupResolver(ctx)
	if err != nil {
		return fmt.Errorf("could not set up custom DNS resolver: %w", err)
	}
	credhubAddrs, credhubPort, err := resolveCredHubInfo(ctx)
	if err != nil {
		return err
	}

	uaaAddrs, uaaPort, err := uaa.GetUAAAddrs(ctx)
	if err != nil {
		return err
	}

	unauthenticatedCCClient, err := cc.NewHTTPClient(ctx)
	if err != nil {
		return err
	}
	tokenURL, err := url.Parse("https://uaa.service.cf.internal:8443/oauth/token")
	if err != nil {
		return err
	}
	client, err := uaa.Authenticate(
		ctx,
		unauthenticatedCCClient,
		tokenURL,
		os.Getenv("OAUTH_CLIENT"),
		os.Getenv("OAUTH_CLIENT_SECRET"),
	)
	if err != nil {
		return err
	}

	ports := []cc.PortInfo{
		cc.PortInfo{
			Addresses:   credhubAddrs,
			Port:        credhubPort,
			Description: "CredHub service access",
		},
		cc.PortInfo{
			Addresses:   uaaAddrs,
			Port:        uaaPort,
			Description: "UAA service access",
		},
	}

	err = cc.SetupCredHubApplicationSecurityGroups(ctx, client, ports)
	if err != nil {
		return fmt.Errorf("error setting security groups: %w", err)
	}
	return nil
}

func main() {
	ctx := context.Background()
	err := process(ctx)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Could not set up CredHub application security groups: %v", err)
		os.Exit(1)
	}
}
