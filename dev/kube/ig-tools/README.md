# Sequencing

## Introduction

One of the problems we have with kubecf is that startup takes too
long, in our perception, and that we do not know where the time goes.

The tooling in this directory is meant to rectify that, somewhat.

## Requirements

The tools must be run with `ruby`.

## Usage

### Watching startup

The main tool is `upwatch.rb`.

Invoke it with the name of the namespace to watch, and redirect its
`stderr` to a file to capture the events it emits. The tool uses
`kubectl` internally to watch the namespace. The environment variable
`KUBECONFIG` can be used to point it at the correct cluster.

Stop watching by aborting the command with Ctrl-C.  It will also automatically
stop watching after all pods in the pod are ready (with a minimum of three pods
to filter out partially completed deployments).

#### Example

```
% pwd
/home/work/SUSE/dev/kubecf-1
% dev/kube/ig-tools/upwatch.rb kubecf 2> sequence.txt
... (continuous display of kubecf state)
^C
%
```

### Postprocessing

The tools `extent.sh` and `sequence.rb` can post-process a sequence/event
file. Invoked with the path to the sequence/event file they
respectively return (on `stdout`)

  - The size of the time interval covered by the events. In other words the time
    required by kubecf to fully start.

  - An SVG-formatted diagram visualizing the sequence of events.

Note that tools like imagemagick, etc. can be used to convert from the
SVG to any number of image raster formats. Similarly there are many
tools to display either the SVG directly, or a raster image derived
from it.

#### Examples

```
% pwd
/home/work/SUSE/dev/kubecf-1
% dev/kube/ig-tools/extent.sh sequence.txt
2831s = 47m:11s
% dev/kube/ig-tools/sequence.rb sequence.txt > sequence.svg
```
