package cc_test

import (
	"context"
	"testing"

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

	server, err := cchelpers.NewMockServer(ctx, t, fakeMount, nil)
	require.NoError(t, err, "could not create mock server with endpoint data")
	defer server.Close()

	client, err := cc.NewHTTPClient(ctx)
	require.NoError(t, err, "could not create new HTTP client")
	require.NotNil(t, client)
}
