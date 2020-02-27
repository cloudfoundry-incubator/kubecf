package quarks

import (
	"context"
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"
)

// Link describes a quarks link; data can be read from it.
type Link struct {
	path string
}

// ResolveLink reads the quarks entanglements (BOSH links) data.
func ResolveLink(ctx context.Context, linkType, linkName string) (*Link, error) {
	mountRoot := GetMountRootFromContext(ctx)
	deploymentName, err := GetDeploymentName(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to resolve BOSH link %s: %w", linkName, err)
	}
	linkPath := filepath.Join(
		mountRoot,
		"quarks", "link",
		deploymentName,
		fmt.Sprintf("%s-%s", linkType, linkName))

	info, err := os.Stat(linkPath)
	if err != nil {
		// os.Stat() fills the error with the path already.
		return nil, fmt.Errorf("failed to resolve BOSH link %s: %w", linkName, err)
	}
	if !info.IsDir() {
		err = fmt.Errorf("%s is not a directory", linkPath)
		return nil, fmt.Errorf("failed to resolve BOSH link %s: %w", linkName, err)
	}
	return &Link{path: linkPath}, nil
}

// Read a BOSH link and return the contents.
func (l *Link) Read(path string) ([]byte, error) {
	linkPath := filepath.Join(l.path, path)
	result, err := ioutil.ReadFile(linkPath)
	if err != nil {
		return nil, fmt.Errorf("failed to read link %s: %w", path, err)
	}
	return result, nil
}
