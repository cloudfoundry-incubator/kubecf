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

	"credhub_setup/cc"
)

func NewMockServer(ctx context.Context, t *testing.T, handler http.Handler) (*httptest.Server, *cc.CCEndpointLinkData, error) {
	server := httptest.NewTLSServer(handler)

	baseURL, err := url.Parse(server.URL)
	if err != nil {
		return nil, nil, fmt.Errorf("could not parse server URL: %w", err)
	}

	endpointData := cc.CCEndpointLinkData{}
	endpointData.CC.InternalServiceHostname = baseURL.Hostname()
	port, err := strconv.Atoi(baseURL.Port())
	if err != nil {
		return nil, nil, fmt.Errorf("could not convert port number: %w", err)
	}
	endpointData.CC.PublicTLS.Port = port

	certBytes := bytes.Buffer{}
	pem.Encode(&certBytes, &pem.Block{
		Type:  "CERTIFICATE",
		Bytes: server.Certificate().Raw,
	})
	endpointData.CC.PublicTLS.CACert = certBytes.String()

	return server, &endpointData, nil
}
