package main

// dns.go includes helper functions dealing with DNS resolution, as we need to
// use the custom BOSH DNS server instead of the Kubernetes default one.

import (
	"context"
	"errors"
	"fmt"
	"net"
	"sync"
	"time"
)

var customResolver *net.Resolver

// setupResolver overrides the default DNS resolver to a custom one; this should
// only be called once.
func setupResolver(ctx context.Context) error {
	if customResolver == nil {
		newResolver, err := getDNSResolver(ctx)
		if err != nil {
			return err
		}
		customResolver = newResolver
	}
	net.DefaultResolver = customResolver
	return nil
}

// getDNSResolver returns a custom DNS resolver that uses the BOSH-DNS service.
func getDNSResolver(ctx context.Context) (*net.Resolver, error) {
	deploymentName, err := getDeploymentName(ctx)
	if err != nil {
		return nil, err
	}
	nameServer := fmt.Sprintf("%s-bosh-dns", deploymentName)
	var addrs []string
	for {
		var dnsError *net.DNSError
		addrs, err = net.LookupHost(nameServer)
		if err != nil && errors.As(err, &dnsError) {
			if dnsError.Temporary() || dnsError.IsNotFound {
				time.Sleep(10 * time.Second)
				continue
			}
		}
		break
	}
	if err != nil {
		return nil, fmt.Errorf("could not look up DNS server %s: %w", nameServer, err)
	}
	mut := sync.Mutex{}
	i := 0
	return &net.Resolver{
		PreferGo: true,
		Dial: func(ctx context.Context, network, address string) (net.Conn, error) {
			mut.Lock()
			defer mut.Unlock()
			overrideAddress := net.JoinHostPort(addrs[i], "53")
			i++
			if i >= len(addrs) {
				i = 0
			}
			dialer := net.Dialer{}
			return dialer.DialContext(ctx, "udp", overrideAddress)
		},
	}, nil
}
