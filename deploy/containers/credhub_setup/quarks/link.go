package quarks

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
)

// ResolveLink reads the quarks entanglements (BOSH links) data.
func ResolveLink(ctx context.Context, name string, data interface{}) error {
	mountRoot := GetMountRootFromContext(ctx)
	deploymentName, err := GetDeploymentName(ctx)
	if err != nil {
		return err
	}
	linkPath := filepath.Join(mountRoot, "quarks/link", deploymentName, name, "link.yaml")
	linkFile, err := os.Open(linkPath)
	if err != nil {
		return fmt.Errorf("could not read link data %s: %w", linkPath, err)
	}
	decoder := json.NewDecoder(linkFile)
	err = decoder.Decode(&data)
	if err != nil {
		return fmt.Errorf("could not read links: %w", err)
	}
	fmt.Fprintf(os.Stderr, "Successfully resolved link %s\n", name)
	return nil
}
