package cc

import (
	"context"
	"encoding/json"
	"fmt"
	"net"
	"net/http"
	"net/url"

	"credhub_setup/httpclient"
	"credhub_setup/quarks"
)

const (
	// The name of the BOSH link
	ccEntanglementName = "cloud_controller_https_endpoint"
)

// ccEndpointLinkData describes the data returned from the cloud controller BOSH
// link (ccEntanglementName)
type ccEndpointLinkData struct {
	CC struct {
		InternalServiceHostname string `json:"internal_service_hostname"`
		PublicTLS               struct {
			CACert string `json:"ca_cert"`
			Port   int    `json:"port"`
		} `json:"public_tls"`
	} `json:"cc"`
}

type ccInfoData struct {
	AuthorizationEndpoint string `json:"authorization_endpoint"`
	TokenEndpoint         string `json:"token_endpoint"`
}

func getCCLinkData(ctx context.Context) (*quarks.Link, error) {
	link, err := quarks.ResolveLink(ctx,ccEntanglementName, ccEntanglementName)
	if err != nil {
		return nil, fmt.Errorf("could not get link: %w", err)
	}
	// Do some sanity checking for empty fields; if they are empty, then we are
	// probably reading an invalid link.
	if _, err := link.Read("cc.internal_service_hostname"); err != nil {
		return nil, fmt.Errorf("could not read internal CC host name: %w", err)
	}
	if _, err := link.Read("cc.public_tls.ca_cert"); err != nil {
		return nil, fmt.Errorf("could not read internal CC CA certificate: %w", err)
	}
	if _, err := link.Read("cc.public_tls.port"); err != nil {
		return nil, fmt.Errorf("could not read internal CC port: %w", err)
	}
	return link, nil
}

// NewHTTPClient returns a HTTP client that is set up to communicate with
// (unauthenticated) endpoints on the cloud controller.
func NewHTTPClient(ctx context.Context) (*http.Client, error) {
	link, err := getCCLinkData(ctx)
	if err != nil {
		return nil, err
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

// GetTokenURL fetches the OAuth token URL from the cloud controller
func GetTokenURL(ctx context.Context, ccClient *http.Client) (*url.URL, error) {
	link, err := getCCLinkData(ctx)
	if err != nil {
		return nil, err
	}
	hostname, err := link.Read("cc.internal_service_hostname")
	if err != nil {
		return nil, fmt.Errorf("could not read internal CC host name: %w", err)
	}
	port, err := link.Read("cc.public_tls.port")
	if err != nil {
		return nil, fmt.Errorf("could not read internal CC port: %w", err)
	}

	ccURL := url.URL{
		Scheme: "https",
		Host:   net.JoinHostPort(string(hostname), string(port)),
		Path:   "/v2/info",
	}
	infoResp, err := ccClient.Get(ccURL.String())
	if err != nil {
		return nil, fmt.Errorf("could not get CC info: %w", err)
	}

	var ccInfo ccInfoData
	err = json.NewDecoder(infoResp.Body).Decode(&ccInfo)
	if err != nil {
		return nil, fmt.Errorf("could not read CC info response: %w", err)
	}

	fmt.Printf("CC info response: %+v\n", ccInfo)
	tokenURL, err := url.Parse(ccInfo.TokenEndpoint)
	if err != nil {
		return nil, fmt.Errorf("invalid token url: %w", err)
	}
	return tokenURL.ResolveReference(&url.URL{Path: "/oauth/token"}), nil
}
