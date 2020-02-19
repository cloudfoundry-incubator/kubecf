package httpclient

import (
	"context"
	"crypto/tls"
	"crypto/x509"
	"fmt"
	"net/http"
	"time"

	"credhub_setup/pkg/quarks"
)

// MakeHTTPClientWithCA returns a new *http.Client that only accepts the given
// CA cert (encoded in PEM format).
func MakeHTTPClientWithCA(ctx context.Context, serverName string, caCert []byte) (*http.Client, error) {
	certPool := x509.NewCertPool()
	ok := certPool.AppendCertsFromPEM(caCert)
	if !ok {
		return nil, fmt.Errorf("could not append CA cert")
	}
	resolver, err := quarks.NewResolver(ctx)
	if err != nil {
		return nil, err
	}
	return &http.Client{
		Transport: &http.Transport{
			DialContext: resolver.DialContext,
			TLSClientConfig: &tls.Config{
				RootCAs:    certPool,
				ServerName: serverName,
			},
		},
		Timeout: 60 * time.Second,
	}, nil
}
