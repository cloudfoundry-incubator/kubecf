package quarks

import (
	"context"
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"
)

type Link struct {
	path string
}

// ResolveLink reads the quarks entanglements (BOSH links) data.
func ResolveLink(ctx context.Context, linkType, linkName string) (*Link, error) {
	mountRoot := GetMountRootFromContext(ctx)
	deploymentName, err := GetDeploymentName(ctx)
	if err != nil {
		return nil, err
	}
	linkPath := filepath.Join(
		mountRoot, 
		"quarks", "link",
		deploymentName, 
		fmt.Sprintf("%s-%s", linkType, linkName))
	
	info, err := os.Stat(linkPath)
	if err != nil {
		filepath.Walk(filepath.Join(mountRoot, "quarks", "link"), func(path string, info os.FileInfo, err error) error {
			fmt.Printf("%s\n", path)
			return nil
		})
		return nil, fmt.Errorf("could not read link data %s: %w", linkPath, err)
	}
	if !info.IsDir() {
		return nil, fmt.Errorf("link %s is not a directory", linkPath)
	}
	return &Link{path: linkPath}, nil
}

func (l *Link) Open(path string) (*os.File, error) {
	linkPath := filepath.Join(l.path, path)
	return os.Open(linkPath)
}

func (l *Link) Read(path string) ([]byte, error) {
	linkPath := filepath.Join(l.path, path)
	return ioutil.ReadFile(linkPath)
}