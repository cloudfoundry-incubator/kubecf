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

var (
	// ResolverSkipBOSHDNS is a context key to use when testing to skip using
	// BOSH DNS, and just use the system resolver instead.
	ResolverSkipBOSHDNS = struct{}{}

	// ResolverOverride is a context key to use when testing to use the
	// specified ResolverHostLookuper for upstream lookups
	ResolverOverride = struct{}{}
)

// ResolverHostLookuper is an interface for a struct that implements the
// net.Resolver.LookupHost method
type ResolverHostLookuper interface {
	// LookupHost looks up the specified host name, as net.Resolver.LookupHost.
	LookupHost(context.Context, string) ([]string, error)
}

// Resolver will resolve host names to IP addresses, and is also responsible for
// having a DialContext method for http.Transport.  The extra layer is required
// to make sure we resolve addresses via BOSH DNS.
type Resolver struct {
	resolver  *net.Resolver
	dnsDialer net.Dialer
	mut       sync.Mutex
	addrs     []string
	index     int
}

// NewResolver creates a new Resolver that can be used to handle DNS lookups via
// BOSH DNS.
func NewResolver(ctx context.Context) (*Resolver, error) {
	// For testing: opt-in to skipping BOSH DNS resolving completely
	// This is necessary so that we don't _always_ try to go via BOSH-DNS, which
	// doesn't even exist in tests.
	if ctx.Value(ResolverSkipBOSHDNS) != nil {
		return &Resolver{
			resolver: net.DefaultResolver,
		}, nil
	}

	deploymentName, err := GetDeploymentName(ctx)
	if err != nil {
		return nil, err
	}

	nameServer := fmt.Sprintf("%s-bosh-dns", deploymentName)
	var baseResolver ResolverHostLookuper
	var ok bool
	// For testing: allow overriding the base resolver we use to find the BOSH
	// DNS server.
	if baseResolver, ok = ctx.Value(ResolverOverride).(ResolverHostLookuper); !ok {
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

	result := &Resolver{
		addrs: addrs,
		index: 0,
	}
	result.resolver = &net.Resolver{
		PreferGo: true,
		Dial:     result.dialForDNS,
	}
	return result, nil
}

// LookupHost looks up the given host using BOSH DNS.  It returns a slice of
// that host's addresses.
func (r *Resolver) LookupHost(ctx context.Context, hostname string) ([]string, error) {
	for {
		addrs, err := r.resolver.LookupHost(ctx, hostname)
		if err == nil {
			fmt.Fprintf(os.Stderr, "\nFound host %s address: %v\n", hostname, addrs)
			return addrs, nil
		}
		var dnsError *net.DNSError
		if !errors.As(err, &dnsError) {
			return nil, fmt.Errorf("could not lookup host %s: %w", hostname, err)
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
	panic("Should not reach unreachable code")
}

// dialForDNS is used to override the underlying resolver's Dial method to
// always make requests to the BOSH DNS server.
func (r *Resolver) dialForDNS(ctx context.Context, network, address string) (net.Conn, error) {
	overrideAddress := func() string {
		// scope the mutex lock to not cover the DialContext call.
		r.mut.Lock()
		defer r.mut.Unlock()
		addr := net.JoinHostPort(r.addrs[r.index], "53")
		r.index++
		if r.index >= len(r.addrs) {
			r.index = 0
		}
		return addr
	}()
	return r.dnsDialer.DialContext(ctx, "udp", overrideAddress)
}

// DialContext forwards to net.Resolver.Dial using the BOSH DNS resolver.
func (r *Resolver) DialContext(ctx context.Context, network, addr string) (net.Conn, error) {
	return (&net.Dialer{
		Resolver: r.resolver,
	}).DialContext(ctx, network, addr)
}
