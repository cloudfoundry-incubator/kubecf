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

	quarkshelpers "credhub_setup/pkg/quarks/testhelpers"
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

	for k, v := range map[string][]byte{
		"internal_service_hostname": []byte(baseURL.Hostname()),
		"public_tls.ca_cert":        certBytes.Bytes(),
		"public_tls.port":           []byte(fmt.Sprintf("%d", port)),
	} {
		const name = "cloud_controller_https_endpoint"
		err := fakeMount.WriteLink(name, name, fmt.Sprintf("cc.%s", k), v)
		if err != nil {
			return nil, err
		}
	}

	return server, nil
}
