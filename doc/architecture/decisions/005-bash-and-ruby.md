# 5. only use bash and ruby for scripting and tooling in kubecf

Date: 2020-07-24

## Status

Accepted

## Context

As the project grows in numbers of contributors and lines of code, we want to make sure we keep the project readable and accessible by 3d party contributors.

## Decision

Only use bash and ruby for scripting and tooling in the KubeCF project.
Ruby scripts should be unit-tested if possible.

## Consequences

Any other existing scripts should be converted to bash or ruby. 
