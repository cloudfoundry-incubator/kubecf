package main

import (
	"flag"
	"io"
	"io/ioutil"
	"log"
	"os"

	"github.com/SUSE/scf/bosh/releases/patches/generator/pkg/generator"
)

const stdinReader = "-"
const stdoutWriter = "-"

func main() {
	var job, instanceGroup, target, patch, output string

	flag.StringVar(&job, "job", "", "the job where the patch is called")
	flag.StringVar(&instanceGroup, "instance-group", "", "the instance group the job is part of")
	flag.StringVar(&target, "target", "", "the target to be patched")
	flag.StringVar(&patch, "patch", stdinReader, "the input path containing the patch to be applied")
	flag.StringVar(&output, "output", stdoutWriter, "the output path to write the ops-file")
	flag.Parse()

	if job == "" {
		log.Fatalf("job must be set")
	}

	if instanceGroup == "" {
		log.Fatalf("instance-group must be set")
	}

	if target == "" {
		log.Fatalf("target must be set")
	}

	var inReader io.Reader
	if patch == stdinReader {
		inReader = os.Stdin
	} else {
		f, err := os.Open(patch)
		if err != nil {
			log.Fatal(err)
		}
		defer f.Close()
		inReader = f
	}

	patchContents, err := ioutil.ReadAll(inReader)
	if err != nil {
		log.Fatal(err)
	}

	var outWriter io.Writer
	if output == stdoutWriter {
		outWriter = os.Stdout
	} else {
		f, err := os.Create(output)
		if err != nil {
			log.Fatal(err)
		}
		defer f.Close()
		outWriter = f
	}

	var g generator.Generator = generator.NewPatchGenerator(outWriter)
	if err := g.Generate(job, instanceGroup, target, patchContents); err != nil {
		log.Fatal(err)
	}
}
