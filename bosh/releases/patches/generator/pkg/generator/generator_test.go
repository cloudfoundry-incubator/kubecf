package generator

import (
	"bytes"
	"fmt"
	"io"
	"io/ioutil"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestNewPatchGenerator(t *testing.T) {
	g := NewPatchGenerator(ioutil.Discard)
	assert.NotNil(t, g)
}

func TestGenerate(t *testing.T) {
	tests := []struct {
		// Inputs.
		name          string
		job           string
		instanceGroup string
		target        string
		contents      []byte
		out           io.ReadWriter

		// Outputs.
		expectedErr error
		expectedOut string
	}{
		{
			name:          "should fail when writing to out fails",
			job:           "bar",
			instanceGroup: "foo",
			target:        "/var/vcap/packages/awesome/baz.sh",
			contents:      []byte("@@ -0,0 +1 @@\n+a change"),
			out:           new(failReadWriter),
			expectedErr:   fmt.Errorf("failed to generate patch: failed to write"),
			expectedOut:   "",
		},
		{
			name:          "should succeed",
			job:           "bar",
			instanceGroup: "foo",
			target:        "/var/vcap/packages/awesome/baz.sh",
			contents:      []byte("@@ -0,0 +1 @@\n+a change"),
			out:           new(bytes.Buffer),
			expectedErr:   nil,
			expectedOut: "- type: replace\n" +
				"  path: /instance_groups/name=foo/jobs/name=bar/properties/bosh_containerization?/pre_render_scripts?/-\n" +
				"  value: |\n" +
				"    set -o errexit\n\n" +
				"    patch --unified '/var/vcap/packages/awesome/baz.sh' <<'EOT'\n" +
				"    @@ -0,0 +1 @@\n" +
				"    +a change\n" +
				"    EOT\n",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			g := &PatchGenerator{
				out: tt.out,
			}
			err := g.Generate(tt.job, tt.instanceGroup, tt.target, tt.contents)
			assert.EqualValues(t, tt.expectedErr, err)
			if err == nil {
				actualOut, err := ioutil.ReadAll(tt.out)
				if !assert.NoError(t, err) {
					return
				}
				assert.Equal(t, tt.expectedOut, string(actualOut))
			}
		})
	}
}

type failReadWriter struct{}

func (*failReadWriter) Read(p []byte) (n int, err error) {
	return 0, fmt.Errorf("failed to read")
}

func (*failReadWriter) Write(p []byte) (n int, err error) {
	return 0, fmt.Errorf("failed to write")
}
