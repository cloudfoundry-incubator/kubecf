---
authors: Vlad Iovanov <VIovanov@suse.com>
state: published
discussion: N/A
---

# RFD 5 Limit the languages, data formats, and tools used by kubecf

## Context

As the project grows in numbers of contributors and lines of code, we want to
make sure we keep the project readable and accessible by external contributors.

To do this we intentionally restrict the choices in scripting languages, data
formats, and supporting tools.

These restrictions apply not only to the kubecf.git repo, but also to
kubecf-tools.git.

## Decision

### Scripting Languages

Only use bash and ruby for scripting and tooling in the KubeCF project.  Ruby
scripts should be unit-tested if possible.

### Statically Typed and/or Compiled Languages

We do not anticipate the need to write any tooling in a compiled language.
Should this become necessary, the Go language should be choosen.

### Templating Languages

Using Go `text/template` based templating is preferred whenever possible.

### Data Formats

Configuration data should be stored in YAML or JSON format.

### External Tools

External tools must be available on both Linux and macOS.

Compiled tools should ideally be available as binary downloads from their Github
releases page.

For tools implemented via scripting languages, tools written in bash or ruby
should be preferred over tools written in other languages whenever this is
possible and functionality is not compromised. It is acceptable to use tools
implemented in other languages if no alternative in bash/ruby exists.

The number of external dependencies should be kept low whenever possible. E.g.
instead of adding a dependency on `yq` use a combination of `ruby` and `jq` to
achieve the same results with existing dependencies.

## Consequences

Any other existing scripts should be converted to bash or ruby. 
