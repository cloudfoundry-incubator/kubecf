package quarks_test

import (
	"context"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"credhub_setup/quarks"
	"credhub_setup/quarks/testhelpers"
)

func TestResolveLink(t *testing.T) {
	t.Parallel()

	const linkName = "linkName"
	const deploymentName = "deploymentName"
	var expected, actual struct {
		Field string `json:"field"`
	}
	expected.Field = "hello"

	ctx, fakeMount, err := testhelpers.GenerateFakeMount(context.Background(), deploymentName, t)
	require.NoError(t, err, "could not set up temporary mount directory")
	defer fakeMount.CleanUp()
	err = fakeMount.WriteLink(linkName, expected)
	require.NoError(t, err, "could not write fake link")

	err = quarks.ResolveLink(ctx, linkName, &actual)
	assert.NoError(t, err, "unexpected error resolving link")
	require.Equal(t, expected, actual, "unexpected link result")
}
