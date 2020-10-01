---
authors: Jaime Gomes <jaime.gomes@suse.com>
state: published
discussion: https://github.com/cloudfoundry-incubator/kubecf/pull/221
---

# RFD 2 git commit messages

## Context

We need to improve the quality of the git commit
messages so developers can easily understand the
context of the proposed changes, throughout a concise and consistent message in order to avoid
lengthy code reviews and project long term maintainability.

Also, a good and structured message will support the automation of the releases notes or at least
reduce the effort to have it.

## Decision

The first interation will rely on generic rules described
[here](https://chris.beams.io/posts/git-commit/), along with some specificities (e.g. GitHub issue
if associated with one).

Most wanted rules:

1. Separate subject from body with a blank line,
2. Limit the subject line to 50 characters,
3. Capitalize the subject line,
4. Wrap the body at 72 characters, and
5. Use the body to explain what and why vs. how.

Other rules are also important!

In order to automate the release notes/changelog process, we will enforce the
[conventional commits](https://www.conventionalcommits.org/en/v1.0.0/) rules usage. 

## Consequences

With the automation of the release process, each git commit to the release branch (i.e. master) or
by merging a pull request, a CI build is triggered and a:

1. git commit message check is performed during squash & merge option selected, and
2. release notes/changelog is automaticaly produced.