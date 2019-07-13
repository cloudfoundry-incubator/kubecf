package generator

import (
	"fmt"
	"io"

	yaml "gopkg.in/yaml.v2"
)

// Generator is the interface that wraps the Generate method that generates a patch ops-file.
type Generator interface {
	Generate(job, instanceGroup, target string, patchContents []byte) error
}

// PatchGenerator satisfies the Generator interface.
type PatchGenerator struct {
	out io.Writer
}

// NewPatchGenerator constructs a new PatchGenerator.
func NewPatchGenerator(out io.Writer) *PatchGenerator {
	return &PatchGenerator{
		out: out,
	}
}

// Generate generates an ops-file for the job in the instanceGroup, containing a pre-render script
// that patches target using patchContents.
func (g *PatchGenerator) Generate(job, instanceGroup, target string, patchContents []byte) error {
	patchScript := fmt.Sprintf(`set -o errexit

patch --unified '%s' <<'EOT'
%s
EOT
`, target, string(patchContents))

	opsPatch := []OpsPatch{{
		Type:  "replace",
		Path:  fmt.Sprintf("/instance_groups/name=%s/jobs/name=%s/properties/bosh_containerization?/pre_render_scripts?/-", instanceGroup, job),
		Value: patchScript,
	}}

	opsPatchYAML, _ := yaml.Marshal(&opsPatch)
	if _, err := g.out.Write(opsPatchYAML); err != nil {
		return fmt.Errorf("failed to generate patch: %v", err)
	}

	return nil
}

// OpsPatch represents an ops-file for a patch that is serialized to YAML.
type OpsPatch struct {
	Type  string `yaml:"type"`
	Path  string `yaml:"path"`
	Value string `yaml:"value"`
}
