package quarks

import (
	"context"
	"errors"
	"fmt"
	"net"
	"os"
	"sync"
	"time"
)

var ResolverSkipBOSHDNS = struct{}{}
var ResolverOverride = struct{}{}

func GetDNSResolver(ctx context.Context) (*net.Resolver, error) {
	// For testing: opt-in to skipping BOSH DNS resolving completely
	// This is necessary so that we don't _always_ try to go via BOSH-DNS, which
	// doesn't even exist in tests.
	if ctx.Value(ResolverSkipBOSHDNS) != nil {
		return net.DefaultResolver, nil
	}

	deploymentName, err := GetDeploymentName(ctx)
	if err != nil {
		return nil, err
	}

	nameServer := fmt.Sprintf("%s-bosh-dns", deploymentName)
	var baseResolver *net.Resolver
	var ok bool
	// For testing: allow overriding the base resolver we use to find the BOSH
	// DNS server.
	if baseResolver, ok = ctx.Value(ResolverOverride).(*net.Resolver); !ok {
		baseResolver = net.DefaultResolver
	}

	var addrs []string
	for {
		var dnsError *net.DNSError
		addrs, err = baseResolver.LookupHost(ctx, nameServer)
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

	// Set up a counter + mutex so we use the various upstream resolvers in
	// round-robin.
	mut := sync.Mutex{}
	i := 0
	return &net.Resolver{
		PreferGo: true,
		Dial: func(ctx context.Context, network, address string) (net.Conn, error) {
			overrideAddress := func() string {
				// scope the mutex lock to not cover the DialContext call.
				mut.Lock()
				defer mut.Unlock()
				addr := net.JoinHostPort(addrs[i], "53")
				i++
				if i >= len(addrs) {
					i = 0
				}
				return addr
			}()
			dialer := net.Dialer{}
			return dialer.DialContext(ctx, "udp", overrideAddress)
		},
	}, nil
}

// ResolveHostToAddrs turns a host name into its IP addresses.
func ResolveHostToAddrs(ctx context.Context, hostname string) ([]string, error) {
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
