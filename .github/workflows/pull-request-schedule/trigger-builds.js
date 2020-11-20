module.exports = async ({ github, context }) => {
    // PullRequestQuery is a GraphQL query to find pull requests with the proper
    // label
    const PullRequestQuery = `
        query($owner: String!, $repo: String!, $label: String!, $cursor: String) {
            repository(owner: $owner, name: $repo) {
                pullRequests(labels: [$label], first: 100, states:OPEN, after: $cursor) {
                    nodes {
                        number
                        timelineItems(last: 100, itemTypes: LABELED_EVENT) {
                            nodes {
                                ... on LabeledEvent {
                                    label { name }
                                    createdAt
                                    actor { login }
                                }
                            }
                        }
                    }
                    pageInfo { endCursor }
                }
            }
        }
    `;

    console.log(`Looking up queued items for ${context.repo.owner}/${context.repo.repo} label ${process.env.LABEL_QUEUE}`);

    // nextPage is a generator function that yields the successive query results
    // of the GraphQL query, limited to just the pull request nodes (as an array).
    const nextPage = async function* () {
        let cursor = null;
        do {
            // queryResult is the result of the GraphQL query
            let queryResult = await github.graphql(PullRequestQuery, {
                owner: context.repo.owner,
                repo: context.repo.repo,
                label: process.env.LABEL_QUEUE,
                cursor: cursor,
            });
            cursor = queryResult.repository.pullRequests.pageInfo.endCursor;
            yield queryResult.repository.pullRequests.nodes;
        } while (cursor !== null);
    }

    // pulls is an array of PR information (with `number` and `timestamp` keys),
    // sorted oldest first.
    let pulls = [];
    for await (let nodes of nextPage()) {
        pulls.push(...nodes.map((pr) => {
            const event = pr.timelineItems.nodes.reverse()
                .find((event) => event.label.name == process.env.LABEL_QUEUE);
            console.log(`Found event for PR#${pr.number}: queued at ${event.createdAt} by ${event.actor.login}`);
            return { number: pr.number, timestamp: Date.parse(event.createdAt) };
        }));
    }
    pulls = pulls.sort((a, b) => a.timestamp - b.timestamp);

    console.log(`Found ${pulls.length} PRs.`);

    // Create an alternative Octokit client instance that can be used to set
    // labels on the PR, using a different GitHub token.  This is required as
    // the tokens passed in by GitHub Actions will not trigger further actions.
    const Octokit = github.constructor;
    const triggeringClient = new Octokit({ auth: process.env.GITHUB_TOKEN });

    for (let pr of pulls.slice(0, process.env.CAPACITY)) {
        console.log(`Queuing PR#${pr.number}`);
        triggeringClient.issues.addLabels({
            owner: context.repo.owner,
            repo: context.repo.repo,
            issue_number: pr.number,
            labels: [process.env.LABEL_TRIGGER]
        });
        github.issues.removeLabel({
            owner: context.repo.owner,
            repo: context.repo.repo,
            issue_number: pr.number,
            name: process.env.LABEL_QUEUE
        });
    }
};
