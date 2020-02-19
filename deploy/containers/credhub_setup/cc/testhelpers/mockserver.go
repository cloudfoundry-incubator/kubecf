package testhelpers

import (
	"bytes"
	"context"
	"encoding/pem"
	"fmt"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strconv"
	"testing"

	quarkshelpers "credhub_setup/quarks/testhelpers"
)

// NewMockServer creates a new mock cloud controller server  that has no
// handlers installed, but does have the appropriate BOSH link structure.
func NewMockServer(ctx context.Context, t *testing.T, fakeMount *quarkshelpers.FakeMountType, handler http.Handler) (*httptest.Server, error) {
	server := httptest.NewTLSServer(handler)

	baseURL, err := url.Parse(server.URL)
	if err != nil {
		return nil, fmt.Errorf("could not parse server URL: %w", err)
	}

	port, err := strconv.Atoi(baseURL.Port())
	if err != nil {
		return nil, fmt.Errorf("could not convert port number: %w", err)
	}

	certBytes := bytes.Buffer{}
	pem.Encode(&certBytes, &pem.Block{
		Type:  "CERTIFICATE",
		Bytes: server.Certificate().Raw,
	})

	err = fakeMount.WriteLink(
		"cloud_controller_https_endpoint",
		map[string]interface{}{
			"cc": map[string]interface{}{
				"internal_service_hostname": baseURL.Hostname(),
				"public_tls": map[string]interface{}{
					"ca_cert": certBytes.String(),
					"port":    port,
				},
			},
		},
	)
	if err != nil {
		return nil, err
	}

	return server, nil
}
