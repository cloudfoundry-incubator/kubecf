package testhelpers

import (
	"context"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"
	"testing"

	"github.com/stretchr/testify/assert"

	"credhub_setup/pkg/quarks"
)

// FakeMountType is the a structure for maintaining information about a fake
// mount used for testing.
type FakeMountType struct {
	deploymentName string
	workDir        string
	t              *testing.T
}

// GenerateFakeMount creates a temporary fake mount point for testing, using the
// given deployment name.
func GenerateFakeMount(ctx context.Context, deploymentName string, t *testing.T) (context.Context, *FakeMountType, error) {
	workDir, err := ioutil.TempDir("", "credhub-setup-test-quarks-link-")
	if err != nil {
		return nil, nil, fmt.Errorf("could not create temporary directory: %w", err)
	}
	mount := &FakeMountType{
		deploymentName: deploymentName,
		workDir:        workDir,
		t:              t,
	}
	defer func() {
		if err != nil {
			mount.CleanUp()
		}
	}()

	podInfoDir := filepath.Join(workDir, "run", "pod-info")
	err = os.MkdirAll(podInfoDir, 0755)
	if err != nil {
		return nil, nil, fmt.Errorf("could not create fake pod info directory: %w", err)
	}
	deploymentNameFile, err := os.Create(filepath.Join(podInfoDir, "deployment-name"))
	if err != nil {
		return nil, nil, fmt.Errorf("could not create fake deployment name file: %w", err)
	}
	_, err = deploymentNameFile.WriteString(deploymentName)
	if err != nil {
		return nil, nil, fmt.Errorf("could not write fake deployment name file: %w", err)
	}
	err = deploymentNameFile.Close()
	if err != nil {
		return nil, nil, fmt.Errorf("could not close deployment name file: %w", err)
	}

	return context.WithValue(ctx, quarks.OverrideMountRoot, mount.workDir), mount, nil
}

// CleanUp removes the temporary data used for the fake mount.
func (m *FakeMountType) CleanUp() error {
	err := os.RemoveAll(m.workDir)
	assert.NoError(m.t, err, "could not clean up fake mount")
	return err
}

// WriteFile writes a file at the given path.  If the given contents is not a
// []byte, it will be JSON encoded before writing.
func (m *FakeMountType) WriteFile(path string, contents interface{}) error {
	mountRelativePath := filepath.Join(m.workDir, path)
	dir := filepath.Dir(mountRelativePath)
	err := os.MkdirAll(dir, 0755)
	if err != nil {
		return fmt.Errorf("could not create fake mount directory %s: %w", dir, err)
	}

	file, err := os.Create(mountRelativePath)
	if err != nil {
		return fmt.Errorf("could not create fake mount file %s: %w", path, err)
	}

	switch obj := contents.(type) {
	case []byte:
		_, err = file.Write(obj)
	default:
		err = json.NewEncoder(file).Encode(contents)
	}
	if err != nil {
		return fmt.Errorf("could not write file %s: %w", path, err)
	}

	return nil
}

// WriteLink writes a link.yaml file used for quarks entanglements into the fake
// mount.  This is a helper method for frequently-used logic.
func (m *FakeMountType) WriteLink(linkType, linkName, key string, contents []byte) error {
	dir := filepath.Join(
		"quarks",
		"link",
		m.deploymentName,
		fmt.Sprintf("%s-%s", linkType, linkName))
	return m.WriteFile(filepath.Join(dir, key), contents)
}
