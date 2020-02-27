package uaa

import (
	"context"
	"fmt"

	"credhub_setup/pkg/quarks"
)

// GetUAAAddrs retrieves the UAA IP addresses and port required for credhub
// setup.
func GetUAAAddrs(ctx context.Context) ([]string, int, error) {
	// TODO: fetch this correctly
	// It's not exposed via a BOSH link, so we'd need to mount a cf-operator
	// internal secret... which all have too much details.
	resolver, err := quarks.NewResolver(ctx)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to get UAA address: %w", err)
	}
	uaaAddrs, err := resolver.LookupHost(ctx, "uaa.service.cf.internal")
	if err != nil {
		return nil, 0, fmt.Errorf("failed to get UAA address: %w", err)
	}
	return uaaAddrs, 8443, nil
}
