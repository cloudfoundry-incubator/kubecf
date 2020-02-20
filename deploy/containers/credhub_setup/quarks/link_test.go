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

	const linkType = "linkType"
	const linkName = "linkName"
	const linkKey = "some.link"
	const deploymentName = "deploymentName"
	expected := []byte("hello")

	ctx, fakeMount, err := testhelpers.GenerateFakeMount(context.Background(), deploymentName, t)
	require.NoError(t, err, "could not set up temporary mount directory")
	defer fakeMount.CleanUp()
	err = fakeMount.WriteLink(linkType, linkName, linkKey, expected)
	require.NoError(t, err, "could not write fake link")

	link, err := quarks.ResolveLink(ctx, linkType, linkName)
	require.NoError(t, err, "unexpected error resolving link")
	require.NotNil(t, link, "resolved link but get nil")

	actual, err := link.Read(linkKey)
	require.NoError(t, err, "unexpected error reading link")
	assert.Equal(t, expected, actual, "unexpected link result")
}
