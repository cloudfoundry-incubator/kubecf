package credhub

// credhub_info.go contains functions to determine the credhub information
// (addresses and port) required for our security groups.

import (
	"context"
	"fmt"
	"net/url"
	"strconv"

	"credhub_setup/pkg/quarks"
)

// resolveCredHubAddrsGivenLink returns the IP addresses of the credhub service.
func resolveCredHubAddrsGivenLink(ctx context.Context, link *quarks.Link) ([]string, error) {
	rawURL, err := link.Read("credhub.internal_url")
	if err != nil {
		return nil, fmt.Errorf("could not read credhub link URL: %w", err)
	}
	credhubURL, err := url.Parse(string(rawURL))
	if err != nil {
		return nil, fmt.Errorf("could not parse credhub link URL %s: %w",
			string(rawURL), err)
	}

	resolver, err := quarks.NewResolver(ctx)
	if err != nil {
		return nil, fmt.Errorf("could not create DNS resolver: %w", err)
	}
	addrs, err := resolver.LookupHost(ctx, credhubURL.Hostname())
	if err != nil {
		return nil, fmt.Errorf("could not resolve credhub hostname: %w", err)
	}
	return addrs, nil
}

// ResolveCredHubInfo returns the IP addresses of the CredHub service and the port.
func ResolveCredHubInfo(ctx context.Context) ([]string, int, error) {
	link, err := quarks.ResolveLink(ctx, "credhub", "credhub")
	if err != nil {
		return nil, 0, err
	}

	credHubAddrs, err := resolveCredHubAddrsGivenLink(ctx, link)
	if err != nil {
		return nil, 0, fmt.Errorf("could not resolve credhub address: %w", err)
	}

	rawPort, err := link.Read("credhub.port")
	if err != nil {
		return nil, 0, fmt.Errorf("could not read credhub link port: %w", err)
	}
	port, err := strconv.Atoi(string(rawPort))
	if err != nil {
		return nil, 0, fmt.Errorf("could not parse credhub link port: %w", err)
	}
	return credHubAddrs, port, nil
}
