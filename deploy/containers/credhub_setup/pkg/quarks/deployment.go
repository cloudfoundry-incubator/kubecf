package quarks

import (
	"context"
	"fmt"
	"io/ioutil"
	"path/filepath"
)

// GetDeploymentName returns the deployment name, which is embedded in some
// names and paths.
func GetDeploymentName(ctx context.Context) (string, error) {
	mountRoot := GetMountRootFromContext(ctx)
	deploymentFileName := filepath.Join(mountRoot, "run", "pod-info", "deployment-name")
	deploymentNameBytes, err := ioutil.ReadFile(deploymentFileName)
	if err != nil {
		return "", fmt.Errorf("could not read redeployment name: %w", err)
	}
	return string(deploymentNameBytes), nil
}
