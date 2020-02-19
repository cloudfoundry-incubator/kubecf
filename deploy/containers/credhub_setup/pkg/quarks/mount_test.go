package quarks_test

import (
	"context"
	"testing"

	"github.com/stretchr/testify/assert"

	"credhub_setup/pkg/quarks"
)

func TestGetMountRootFromContext(t *testing.T) {
	t.Parallel()
	t.Run("with override", func(t *testing.T) {
		t.Parallel()
		expected := "pikachu"
		ctx := context.WithValue(
			context.Background(),
			quarks.OverrideMountRoot,
			expected)
		actual := quarks.GetMountRootFromContext(ctx)
		assert.Equal(t, expected, actual)
	})
	t.Run("without override", func(t *testing.T) {
		t.Parallel()
		actual := quarks.GetMountRootFromContext(context.Background())
		assert.Equal(t, "/", actual)
	})
}
