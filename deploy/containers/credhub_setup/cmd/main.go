// credhub_setup is a command used to set up CF application security groups so
// that applications can communicate with the internal CredHub endpoint, as well
// as UAA if appropriate.
package main

import (
	"context"
	"fmt"
	"net/url"
	"os"

	"credhub_setup/pkg/cc"
	"credhub_setup/pkg/credhub"
	"credhub_setup/pkg/uaa"
)

func process(ctx context.Context) error {
	ctx, cancelFunc := context.WithCancel(ctx)
	defer cancelFunc()

	credhubAddrs, credhubPort, err := credhub.ResolveCredHubInfo(ctx)
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

	endpoints := []cc.EndpointInfo{
		cc.EndpointInfo{
			Addresses:   credhubAddrs,
			Port:        credhubPort,
			Description: "CredHub service access",
		},
		cc.EndpointInfo{
			Addresses:   uaaAddrs,
			Port:        uaaPort,
			Description: "UAA service access",
		},
	}

	if err := cc.SetupCredHubApplicationSecurityGroups(ctx, client, endpoints); err != nil {
		return fmt.Errorf("error setting security groups: %w", err)
	}
	return nil
}

func main() {
	ctx := context.Background()
	if err := process(ctx); err != nil {
		fmt.Fprintf(os.Stderr, "Could not set up CredHub application security groups: %v", err)
		os.Exit(1)
	}
}
