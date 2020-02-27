package credhub

import (
	"context"
	"fmt"
	"net/url"
	"strconv"

	"credhub_setup/pkg/quarks"
)

// resolveCredHubAddrsGivenLink returns the IP addresses of the credhub service.
func resolveCredHubAddrsGivenLink(ctx context.Context, link *quarks.Link) ([]string, error) {
	const errorMessage = "failed to resolve credhub addresses"
	rawURL, err := link.Read("credhub.internal_url")
	if err != nil {
		return nil, fmt.Errorf("%s: could not read URL: %w", errorMessage, err)
	}
	credhubURL, err := url.Parse(string(rawURL))
	if err != nil {
		return nil, fmt.Errorf("%s: could not parse URL %s: %w",
			errorMessage, string(rawURL), err)
	}

	resolver, err := quarks.NewResolver(ctx)
	if err != nil {
		return nil, fmt.Errorf("%s: %w", errorMessage, err)
	}
	addrs, err := resolver.LookupHost(ctx, credhubURL.Hostname())
	if err != nil {
		return nil, fmt.Errorf("%s: %w", errorMessage, err)
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
		return nil, 0, fmt.Errorf("failed to resolve credhub info: %w", err)
	}

	rawPort, err := link.Read("credhub.port")
	if err != nil {
		return nil, 0, fmt.Errorf("failed to resolve credhub info: %w", err)
	}
	port, err := strconv.Atoi(string(rawPort))
	if err != nil {
		return nil, 0, fmt.Errorf("failed to resolve credhub info: %w", err)
	}
	return credHubAddrs, port, nil
}
