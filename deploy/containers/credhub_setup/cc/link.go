package cc

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"

	"credhub_setup/httpclient"
	"credhub_setup/quarks"
)

// CEndpointLinkData describes the data returned from the cloud controller BOSH
// link (ccEntanglementName)
type CCEndpointLinkData struct {
	CC struct {
		InternalServiceHostname string `json:"internal_service_hostname"`
		PublicTLS               struct {
			CACert string `json:"ca_cert"`
			Port   int    `json:"port"`
		} `json:"public_tls"`
	} `json:"cc"`
}

type CCInfoData struct {
	AuthorizationEndpoint string `json:"authorization_endpoint"`
	TokenEndpoint         string `json:"token_endpoint"`
}

func getCCLinkData(ctx context.Context) (*CCEndpointLinkData, error) {
	var link CCEndpointLinkData
	err := quarks.ResolveLink(ctx, "cloud_controller_https_endpoint", &link)
	if err != nil {
		return nil, fmt.Errorf("could not get link: %w", err)
	}
	// Do some sanity checking for empty fields; if they are empty, then we are
	// probably reading an invalid link.
	if link.CC.InternalServiceHostname == "" {
		return nil, fmt.Errorf("empty internal CC host name")
	}
	if link.CC.PublicTLS.CACert == "" {
		return nil, fmt.Errorf("empty internal CC CA certificate")
	}
	if link.CC.PublicTLS.Port == 0 {
		return nil, fmt.Errorf("empty internal CC port")
	}
	return &link, nil
}

// NewHTTPClient returns a HTTP client that is set up to communicate with
// (unauthenticated) endpoints on the cloud controller.
func NewHTTPClient(ctx context.Context) (*http.Client, error) {
	link, err := getCCLinkData(ctx)
	if err != nil {
		return nil, err
	}
	client, err := httpclient.MakeHTTPClientWithCA(
		link.CC.InternalServiceHostname,
		[]byte(link.CC.PublicTLS.CACert))
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
	ccURL := url.URL{
		Scheme: "https",
		Host:   fmt.Sprintf("%s:%d", link.CC.InternalServiceHostname, link.CC.PublicTLS.Port),
		Path:   "/v2/info",
	}
	infoResp, err := ccClient.Get(ccURL.String())
	if err != nil {
		return nil, fmt.Errorf("could not get CC info: %w", err)
	}

	var ccInfo CCInfoData
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
