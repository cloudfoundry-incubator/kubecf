# Contributing to KubeCF

First, thanks for taking the time to contribute to the project! Your support is highly appreciated - kudos!

The following is a set of guidelines for contributing to KubeCF and its modules. These are mostly guidelines, not rules.
Use your best judgment and feel free to propose changes to this document in a pull request.

## How to contribute

Please report to the CloudFoundry foundation <security@cloudfoundry.org> and we will fix the issues as quickly as we can before the the details are shared with the public
For more information check the CloudFoundry Security [page](https://www.cloudfoundry.org/security/).

When contributing to this repository, please first discuss the changes through an existent Github issue with the main contributors.

## Issues tracker

We're commited to have short and accurate templates for different type of issues in order to gather the required
information to start a conversation.

Once again, feel free to contribute to improve them by opening a pull request.

### How to report a bug

Start by searching [bugs][1] for some similiar issues and/or extra information. If you are unable to find any relevant
information from your search, then open an issue by selecting the issue type "Bug" and fill the template accurately as possible.

### How to suggest a feature/enhancement

If you would like to request a feature that does not yet exist in KubeCF you should do a quick [search][2] - someone
may already have opened the same feature request. If not, go ahead and open a new issue by selecting the "Feature" issue type and answer some needed questions.

## Code review process

The core team looks at Pull Requests on a regular basis on a best-effort basis.

## How are Github issues handled

### Columns

1. Icebox: New issues that require further grooming. Note that some issues may be closed or rejected.

2. To Do: issues ordered by priority and ready to be picked by contributors.

3. In progress: issues being implemented.

4. Under review: issues waiting to be reviewed.

5. Done: all issues closed.

### Labels

For tracking purposes, issues are labeled based on their **priority**, **status**, **type** and **size**.
There're some individual labels like **good first issues** or **help wanted**, that can be used but are not tracked from
a project management perspecitve.

All the grouping labels must contain a short description to help contributors to understand better the intention of
each one.

#### Status

1. **Accepted**: issue was accepted and it may be implemented in near future.
2. **Need More Info**: issue requires more information to be evaluated.
3. **Verification Needed**: issue probably waiting for a PR to be merged.
4. **Validation**: issue has enough information but it requires a discussion before accepted.

[todo] more about the labels grouping in future versions of the document.

### Creating New Issues

The issue created on Github will be automatically assigned to the product owner, who will then evaluate it.

If the issue does not contain sufficient information the author will be requested to provide additional details.

When an issue goes "Stale" (more than 60 days without any activity), the product owner will:

1. close the issue in case of lack of information.
2. close the issue if it's no longer relevant.
3. change labels if it's still relevant and information is sufficient.

### Where to start

All contributions are welcome but the best place to pick an issue to work on is from the _todo_ column that is ordered by
priority. Before you move it to the _in progess_ column, make sure that the story is clear. If not, add your comments and/or 
questions to the issue.

### How do we estimate

We use Fibonnaci number sizes (1,2,3,5,8,13,21) to determine the Github issue complexity and not the implementation effort, so we can determine if the issue needs to be split in multiple ones and/or if it requires a more extended brainstorm to determine the feasibility of the new feature.

### The flow

The issue flow is always to the right that means if you pick an issue from the _todo_ column, you should work on it until
it's ready to be reviewed by a peer.

If you need to move the issue back to a previous column, then please leave a clear comment stating the reasons so the
project core contributors can refine it.

1. pick an issue from the _todo_ column and move it to the in progress.
2. add your name to the assignee field and other member's name if they are pairing with you.
3. create a Pull Request and
[link](https://help.github.com/en/github/managing-your-work-on-github/linking-a-pull-request-to-an-issue) the open issue
that will be fixed when merged.

### Milestone(s)

Still open to discussion about the rationality but I am proposing to use it only to mark the issues done on each release
version and not before.

## Community

You can chat with the core team on Slack channel #kubecf-dev.

## Code of conduct

Please refer to [Code of Conduct](code-of-conduct.md)

## Links

- [Bugs][1]
- [Features][2]
- [More detailed Contibuting guide][doc/Contribute.md]

[1]: https://github.com/issues?utf8=%E2%9C%93&q=repo%3ASUSE%2Fkubecf+is%3Aopen+is%3Aissue+label%3A%22bug+%F0%9F%90%9B%22

[2]: https://github.com/issues?utf8=%E2%9C%93&q=repo%3ASUSE%2Fkubecf+is%3Aissue+label%3A%22enhancement+%E2%9C%A8%22
