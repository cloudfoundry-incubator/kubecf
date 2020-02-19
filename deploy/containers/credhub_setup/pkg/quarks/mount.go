package quarks

import "context"

// OverrideMountRoot is a context key for testing; if the context has this, we
// prefix the normal kube-mounted paths with it.
var OverrideMountRoot = struct{}{}

// GetMountRootFromContext returns the appropriate root of the filesystem tree
// given the context; the context only has an override for testing.
func GetMountRootFromContext(ctx context.Context) string {
	if override, ok := ctx.Value(OverrideMountRoot).(string); ok {
		return override
	}
	return "/"
}
