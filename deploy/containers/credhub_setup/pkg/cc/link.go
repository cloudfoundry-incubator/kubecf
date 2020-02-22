package cc

import (
	"context"
	"fmt"
	"net/http"

	"credhub_setup/pkg/httpclient"
	"credhub_setup/pkg/quarks"
)

const (
	// The name of the BOSH link
	ccEntanglementName = "cloud_controller_https_endpoint"
)

// NewHTTPClient returns a HTTP client that is set up to communicate with
// (unauthenticated) endpoints on the cloud controller.
func NewHTTPClient(ctx context.Context) (*http.Client, error) {
	link, err := quarks.ResolveLink(ctx, ccEntanglementName, ccEntanglementName)
	if err != nil {
		return nil, fmt.Errorf("could not get link: %w", err)
	}
	hostname, err := link.Read("cc.internal_service_hostname")
	if err != nil {
		return nil, fmt.Errorf("could not read internal CC host name: %w", err)
	}
	caCert, err := link.Read("cc.public_tls.ca_cert")
	if err != nil {
		return nil, fmt.Errorf("could not read internal CC CA certificate: %w", err)
	}
	client, err := httpclient.MakeHTTPClientWithCA(ctx, string(hostname), caCert)
	if err != nil {
		return nil, fmt.Errorf("could not create HTTP client with CA: %w", err)
	}
	return client, nil
}
