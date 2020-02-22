package uaa

import (
	"context"
	"fmt"
	"io/ioutil"
	"net/http"
	"net/url"
	"path/filepath"

	"golang.org/x/oauth2"
	"golang.org/x/oauth2/clientcredentials"

	"credhub_setup/pkg/httpclient"
	"credhub_setup/pkg/quarks"
)

// Authenticate with UAA, returning a suitable HTTP client.
func Authenticate(ctx context.Context, ccClient *http.Client, tokenURL *url.URL, clientID, clientSecret string) (*http.Client, error) {
	credentialsConfig := clientcredentials.Config{
		ClientID:     clientID,
		ClientSecret: clientSecret,
		TokenURL:     tokenURL.String(),
		Scopes:       []string{"cloud_controller.admin"},
	}

	certPath := filepath.Join(quarks.GetMountRootFromContext(ctx), "run", "uaa-ca-cert", "ca.crt")
	uaaCABytes, err := ioutil.ReadFile(certPath)
	if err != nil {
		return nil, fmt.Errorf("error reading UAA CA certificate: %w", err)
	}
	uaaClient, err := httpclient.MakeHTTPClientWithCA(
		ctx,
		tokenURL.Hostname(),
		uaaCABytes)
	if err != nil {
		return nil, fmt.Errorf("could not add UAA CA: %w", err)
	}
	uaaContext := context.WithValue(ctx, oauth2.HTTPClient, uaaClient)

	ccContext := context.WithValue(ctx, oauth2.HTTPClient, ccClient)
	client := oauth2.NewClient(ccContext, credentialsConfig.TokenSource(uaaContext))
	return client, nil
}
