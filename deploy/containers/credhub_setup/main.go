// credhub_setup is a command used to set up CF application security groups so
// that applications can communicate with the internal CredHub endpoint, as well
// as UAA if appropriate.
package main

import (
	"context"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"
)

// overrideMountRoot is a context key for testing; if the context has this, we
// prefix the normal kube-mounted paths with it.
var overrideMountRoot = struct{}{}

// getMountRootFromContext returns the appropriate root of the filesystem tree
// given the context; the context only has an override for testing.
func getMountRootFromContext(ctx context.Context) string {
	if override, ok := ctx.Value(overrideMountRoot).(string); ok {
		return override
	}
	return "/"
}

// getDeploymentName returns the deployment name, which is embedded in some
// names and paths.
func getDeploymentName(ctx context.Context) (string, error) {
	mountRoot := getMountRootFromContext(ctx)
	deploymentFileName := filepath.Join(mountRoot, "run/pod-info/deployment-name")
	deploymentNameBytes, err := ioutil.ReadFile(deploymentFileName)
	if err != nil {
		return "", fmt.Errorf("could not read redeployment name: %w", err)
	}
	return string(deploymentNameBytes), nil
}

// resolveLink reads the quarks entanglements (BOSH links) data.
func resolveLink(ctx context.Context, name string, data interface{}) error {
	mountRoot := getMountRootFromContext(ctx)
	deploymentName, err := getDeploymentName(ctx)
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

// portInfo describes a port to be opened
type portInfo struct {
	addresses   []string
	port        int
	description string
}

func process(ctx context.Context) error {
	err := setupResolver(ctx)
	if err != nil {
		return fmt.Errorf("could not set up custom DNS resolver: %w", err)
	}
	ports, err := resolveCredHubInfo(ctx)
	if err != nil {
		return err
	}
	client, err := authenticate(
		ctx,
		os.Getenv("OAUTH_CLIENT"),
		os.Getenv("OAUTH_CLIENT_SECRET"),
	)
	if err != nil {
		return err
	}
	err = setupCredHubApplicationSecurityGroups(ctx, client, ports)
	if err != nil {
		return fmt.Errorf("error setting security groups: %w", err)
	}
	return nil
}

func main() {
	ctx := context.Background()
	err := process(ctx)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Could not set up CredHub application security groups: %v", err)
		os.Exit(1)
	}
}
