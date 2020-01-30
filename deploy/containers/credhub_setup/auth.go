package main

// This file contains code to deal with UAA / authentication.

import (
	"context"
	"crypto/tls"
	"crypto/x509"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"net/url"
	"path/filepath"
	"time"

	"golang.org/x/oauth2"
	"golang.org/x/oauth2/clientcredentials"
)

func makeHTTPClientWithCA(serverName string, caCert []byte) (*http.Client, error) {
	certPool, err := x509.SystemCertPool()
	if err != nil {
		return nil, fmt.Errorf("could not get system cert pool: %w", err)
	}
	ok := certPool.AppendCertsFromPEM(caCert)
	if !ok {
		fmt.Printf("Warning: failed to add CA certs for %s\n", serverName)
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

// authenticate with UAA, returning the access token and refresh token.
func authenticate(ctx context.Context, clientID, clientSecret string) (*http.Client, error) {
	link, err := getCCLinkData(ctx)
	if err != nil {
		return nil, err
	}
	ccClient, err := makeHTTPClientWithCA(link.CC.InternalServiceHostname, []byte(link.CC.PublicTLS.CACert))
	if err != nil {
		return nil, fmt.Errorf("could not make CC HTTP client: %w", err)
	}

	tokenURL, err := getTokenURL(ctx, link, ccClient)
	if err != nil {
		return nil, fmt.Errorf("could not get UAA token URL: %w", err)
	}

	credentialsConfig := clientcredentials.Config{
		ClientID:     clientID,
		ClientSecret: clientSecret,
		TokenURL:     tokenURL.String(),
		Scopes:       []string{"cloud_controller.admin"},
	}

	fmt.Printf("Got UAA token URL: %s\n", tokenURL.String())
	certPath := filepath.Join(getMountRootFromContext(ctx), "run/uaa-ca-cert/ca.crt")
	uaaCABytes, err := ioutil.ReadFile(certPath)
	if err != nil {
		return nil, fmt.Errorf("error reading UAA CA certificate: %w", err)
	}
	uaaClient, err := makeHTTPClientWithCA(tokenURL.Hostname(), uaaCABytes)
	if err != nil {
		return nil, fmt.Errorf("could not make UAA HTTP client: %w", err)
	}
	uaaContext := context.WithValue(ctx, oauth2.HTTPClient, uaaClient)

	ccContext := context.WithValue(ctx, oauth2.HTTPClient, ccClient)
	client := oauth2.NewClient(ccContext, credentialsConfig.TokenSource(uaaContext))
	return client, nil
}

type ccInfoData struct {
	AuthorizationEndpoint string `json:"authorization_endpoint"`
	TokenEndpoint         string `json:"token_endpoint"`
}

func getCCLinkData(ctx context.Context) (*ccEndpointLinkData, error) {
	var link ccEndpointLinkData
	err := resolveLink(ctx, "cloud_controller_https_endpoint", &link)
	if err != nil {
		return nil, fmt.Errorf("could not get link: %w", err)
	}
	return &link, nil
}

// getTokenURL fetches the OAuth token URL from the cloud controller
func getTokenURL(ctx context.Context, link *ccEndpointLinkData, ccClient *http.Client) (*url.URL, error) {
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
