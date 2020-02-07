package httpclient

import (
	"crypto/tls"
	"crypto/x509"
	"fmt"
	"net/http"
	"time"
)

// MakeHTTPClientWithCA returns a new *http.Client that only accepts the given
// CA cert (encoded in PEM format).
func MakeHTTPClientWithCA(serverName string, caCert []byte) (*http.Client, error) {
	certPool := x509.NewCertPool()
	ok := certPool.AppendCertsFromPEM(caCert)
	if !ok {
		return nil, fmt.Errorf("could not append CA cert")
	}
	return &http.Client{
		Transport: &http.Transport{
			TLSClientConfig: &tls.Config{
				RootCAs:    certPool,
				ServerName: serverName,
			},
		},
		Timeout: 60 * time.Second,
	}, nil
}
