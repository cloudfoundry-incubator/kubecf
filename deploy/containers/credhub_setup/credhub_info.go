package main

// credhub_info.go contains functions to determine the credhub information
// (addresses and port) required for our security groups.

import (
	"context"
	"fmt"
	"net/url"

	"credhub_setup/quarks"
)

// credhubLinkData is the quarks entanglement data structure for the credhub link
type credhubLinkData struct {
	CredHub struct {
		InternalURL string `json:"internal_url"`
		Port        int    `json:"port"`
	} `json:"credhub"`
}

// resolveCredHubAddrsGivenLink returns the IP addresses of the credhub service.
func resolveCredHubAddrsGivenLink(ctx context.Context, link credhubLinkData) ([]string, error) {
	credhubURL, err := url.Parse(link.CredHub.InternalURL)
	if err != nil {
		return nil, fmt.Errorf("could not parse credhub link URL %s: %w",
			link.CredHub.InternalURL, err)
	}

	addrs, err := quarks.ResolveHostToAddrs(ctx, credhubURL.Hostname())
	if err != nil {
		return nil, fmt.Errorf("could not resolve credhub hostname: %w", err)
	}
	return addrs, nil
}

// resolveCredHubInfo returns the IP addresses of the CredHub service and the port.
func resolveCredHubInfo(ctx context.Context) ([]string, int, error) {
	var link credhubLinkData
	err := quarks.ResolveLink(ctx, "credhub", &link)
	if err != nil {
		return nil, 0, err
	}

	credHubAddrs, err := resolveCredHubAddrsGivenLink(ctx, link)
	if err != nil {
		return nil, 0, fmt.Errorf("could not resolve credhub address: %w", err)
	}
	return credHubAddrs, link.CredHub.Port, nil
}
