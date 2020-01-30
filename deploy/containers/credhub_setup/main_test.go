package main

import (
	"context"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

type fakeMountType struct {
	deploymentName string
	workDir        string
	t *testing.T
}

func generateFakeMount(deploymentName string, t *testing.T) (*fakeMountType, error) {
	workDir, err := ioutil.TempDir("", "credhub-setup-test-quarks-link-")
	if err != nil {
		return nil, fmt.Errorf("could not create temporary directory: %w", err)
	}
	mount := &fakeMountType{
		deploymentName: deploymentName,
		workDir:        workDir,
		t:t,
	}
	defer func() {
		if err != nil {
			mount.cleanup()
		}
	}()

	podInfoDir := filepath.Join(workDir, "run/pod-info")
	err = os.MkdirAll(podInfoDir, 0755)
	if err != nil {
		return nil, fmt.Errorf("could not create fake pod info directory: %w", err)
	}
	deploymentNameFile, err := os.Create(filepath.Join(podInfoDir, "deployment-name"))
	if err != nil {
		return nil, fmt.Errorf("could not create fake deployment name file: %w", err)
	}
	_, err = deploymentNameFile.WriteString(deploymentName)
	if err != nil {
		return nil, fmt.Errorf("could not write fake deployment name file: %w", err)
	}
	err = deploymentNameFile.Close()
	if err != nil {
		return nil, fmt.Errorf("could not close deployment name file: %w", err)
	}

	return mount, nil
}

func (m *fakeMountType) cleanup() error {
	err := os.RemoveAll(m.workDir)
	assert.NoError(m.t, err, "could not clean up fake mount")
	return err
}

func (m *fakeMountType) writeFile(name string, contents interface{}) error {
	filePath := filepath.Join(m.workDir, name)
	dir := filepath.Dir(filePath)
	err := os.MkdirAll(dir, 0755)
	if err != nil {
		return fmt.Errorf("could not create fake mount directory %s: %w", dir, err)
	}

	file, err := os.Create(filePath)
	if err != nil {
		return fmt.Errorf("could not create fake mount file %s: %w", name, err)
	}

	switch obj := contents.(type) {
	case []byte:
		_, err = file.Write(obj)
	default:
		err = json.NewEncoder(file).Encode(contents)
	}
	if err != nil {
		return fmt.Errorf("could not write file %s: %w", name, err)
	}

	return nil
}

func (m *fakeMountType) writeLink(name string, contents interface{}) error {
	path := filepath.Join("quarks", "link", m.deploymentName, name, "link.yaml")
	return m.writeFile(path, contents)
}

func TestResolveLink(t *testing.T) {
	t.Parallel()

	const linkName = "linkName"
	const deploymentName = "deploymentName"
	var expected, actual struct {
		Field string `json:"field"`
	}
	expected.Field = "hello"

	fakeMount, err := generateFakeMount(deploymentName, t)
	require.NoError(t, err, "could not set up temporary mount directory")
	defer fakeMount.cleanup()
	err = fakeMount.writeLink(linkName, expected)
	require.NoError(t, err, "could not write fake link")

	ctx := context.WithValue(context.Background(), overrideMountRoot, fakeMount.workDir)
	err = resolveLink(ctx, linkName, &actual)
	require.Equal(t, expected, actual, "unexpected link result")
}
