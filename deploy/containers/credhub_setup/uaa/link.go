package uaa

import (
	"context"
	"fmt"

	"credhub_setup/quarks"
)

// GetUAAAddrs retrieves the UAA IP addresses and port required for credhub
// setup.
func GetUAAAddrs(ctx context.Context) ([]string, int, error) {
	// TODO: fetch this correctly
	// It's not exposed via a BOSH link, so we'd need to mount a cf-operator
	// internal secret... which all have too much details.
	uaaAddrs, err := quarks.ResolveHostToAddrs(ctx, "uaa.service.cf.internal")
	if err != nil {
		return nil, 0, fmt.Errorf("could not resolve UAA address: %w", err)
	}
	return uaaAddrs, 8443, nil
}
