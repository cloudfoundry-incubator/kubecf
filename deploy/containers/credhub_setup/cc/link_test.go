package cc_test

import (
	"context"
	"encoding/json"
	"net/http"
	"net/url"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"credhub_setup/cc"
	cchelpers "credhub_setup/cc/testhelpers"
	quarkshelpers "credhub_setup/quarks/testhelpers"
)

func TestNewHTTPClient(t *testing.T) {
	t.Parallel()
	ctx, fakeMount, err := quarkshelpers.GenerateFakeMount(
		context.Background(),
		"http-client",
		t)
	require.NoError(t, err, "could not generate fake mount")
	defer fakeMount.CleanUp()

	server, link, err := cchelpers.NewMockServer(ctx, t, nil)
	require.NoError(t, err, "could not create mock server with endpoint data")
	defer server.Close()

	err = fakeMount.WriteLink("cloud_controller_https_endpoint", link)
	require.NoError(t, err, "could not write BOSH link information")

	client, err := cc.NewHTTPClient(ctx)
	require.NoError(t, err, "could not create new HTTP client")
	require.NotNil(t, client)
}

func TestGetTokenURL(t *testing.T) {
	t.Parallel()
	ctx := context.Background()
	ctx, fakeMount, err := quarkshelpers.GenerateFakeMount(ctx, "token-url", t)
	require.NoError(t, err, "could not set up fake mount")
	defer fakeMount.CleanUp()

	mux := http.NewServeMux()
	server, linkData, err := cchelpers.NewMockServer(ctx, t, mux)
	require.NoError(t, err, "could not set up mock CC server")
	defer server.Close()

	err = fakeMount.WriteLink("cloud_controller_https_endpoint", linkData)
	require.NoError(t, err, "could not write CC BOSH link data")

	baseURL, err := url.Parse(server.URL)
	expectedTokenURL := baseURL.ResolveReference(&url.URL{Path: "/oauth/token"})
	require.NoError(t, err, "could not parse base URL")
	mux.HandleFunc("/v2/info", func(w http.ResponseWriter, req *http.Request) {
		_ = json.NewEncoder(w).Encode(cc.CCInfoData{
			AuthorizationEndpoint: "",
			TokenEndpoint:         baseURL.String(),
		})
	})

	tokenURL, err := cc.GetTokenURL(ctx, server.Client())
	require.NoError(t, err, "could not get token URL")
	assert.Equal(t, expectedTokenURL, tokenURL, "got unexpected token URL")
}
