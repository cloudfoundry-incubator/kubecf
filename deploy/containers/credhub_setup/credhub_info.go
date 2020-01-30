package main

// credhub_info.go contains functions to determine the credhub information
// (addresses and port) required for our security groups.

import (
	"context"
	"errors"
	"fmt"
	"net"
	"net/url"
	"os"
	"time"
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

	addrs, err := resolveHostToAddrs(ctx, credhubURL.Hostname())
	if err != nil {
		return nil, fmt.Errorf("could not resolve credhub hostname: %w", err)
	}
	return addrs, nil
}

// resolveHostToAddrs turns a host name into its IP addresses.
func resolveHostToAddrs(ctx context.Context, hostname string) ([]string, error) {
	var addrs []string
	var err error
	fmt.Fprintf(os.Stderr, "Looking up host %s", hostname)
	for {
		addrs, err = net.DefaultResolver.LookupHost(ctx, hostname)
		var dnsError *net.DNSError
		if !errors.As(err, &dnsError) {
			break
		}
		if !(dnsError.Temporary() || dnsError.IsNotFound) {
			// Unexpected DNS error; report and die
			return nil, fmt.Errorf("error looking up host %s: %w", hostname, err)
		}
		// If CredHub has not finished starting up, DNS resolution will fail
		// (even though the credhub service address is fixed); wait a bit and
		// try again until we succeed (to not blow through our retry quota and
		// end up in CrashLoopBackoff).
		fmt.Fprintf(os.Stderr, ".")
		time.Sleep(10 * time.Second)
	}
	if err != nil {
		return nil, fmt.Errorf("could not lookup host %s: %w", hostname, err)
	}
	fmt.Fprintf(os.Stderr, "\nFound host %s address: %v\n", hostname, addrs)

	return addrs, nil
}

// resolveCredHubInfo returns the IP addresses of the CredHub service and the port.
func resolveCredHubInfo(ctx context.Context) ([]portInfo, error) {
	var link credhubLinkData
	err := resolveLink(ctx, "credhub", &link)
	if err != nil {
		return nil, err
	}

	var result []portInfo

	credHubAddrs, err := resolveCredHubAddrsGivenLink(ctx, link)
	if err != nil {
		return nil, fmt.Errorf("could not resolve credhub address: %w", err)
	}
	result = append(result, portInfo{
		addresses:   credHubAddrs,
		port:        link.CredHub.Port,
		description: "CredHub service access",
	})

	// TODO: fetch this correctly
	// It's not exposed via a BOSH link, so we'd need to mount a cf-operator
	// internal secret... which all have too much details.
	uaaAddrs, err := resolveHostToAddrs(ctx, "uaa.service.cf.internal")
	if err != nil {
		return nil, fmt.Errorf("could not resolve UAA address: %w", err)
	}
	result = append(result, portInfo{
		addresses:   uaaAddrs,
		port:        8443,
		description: "UAA service access",
	})

	return result, nil
}
