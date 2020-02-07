package quarks

import (
	"context"
	"errors"
	"fmt"
	"net"
	"os"
	"time"
)

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
