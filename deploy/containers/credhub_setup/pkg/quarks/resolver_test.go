package quarks

import (
	"context"
	"net"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestNewResolver(t *testing.T) {
	t.Run("override with default resolver for testing", func(t *testing.T) {
		ctx := context.WithValue(
			context.Background(),
			ResolverSkipBOSHDNS,
			struct{}{})
		resolver, err := NewResolver(ctx)
		assert.NoError(t, err, "error getting resolver")
		assert.Equal(t,
			net.DefaultResolver,
			resolver.resolver,
			"unexpected resolver")
	})
}
