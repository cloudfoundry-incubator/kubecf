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

func getCCLinkData(ctx context.Context) (*ccEndpointLinkData, error) {
	var link ccEndpointLinkData
	err := quarks.ResolveLink(ctx, "cloud_controller_https_endpoint", &link)
	if err != nil {
		return nil, fmt.Errorf("could not get link: %w", err)
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
	return httpclient.MakeHTTPClientWithCA(
		link.CC.InternalServiceHostname,
		[]byte(link.CC.PublicTLS.CACert))
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
	tokenURL.Path += "/oauth/token"
	return tokenURL, nil
}
