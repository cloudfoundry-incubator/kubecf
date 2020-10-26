module.exports = async ({ github, context }) => {
    // PullRequestQuery is a GraphQL query to find pull requests with the proper
    // label
    const PullRequestQuery = `
        query($owner: String!, $repo: String!, $label: String!) {
            repository(owner: $owner, name: $repo) {
                labels(first: 10, query: $label) {
                    nodes {
                        name
                        pullRequests(states: OPEN, last: 10) {
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
                        }
                    }
                }
            }
        }
    `;

    console.log(`Looking up queued items for ${context.repo.owner}/${context.repo.repo}`);

    // queryResult is the result of the GraphQL query
    const queryResult = await github.graphql(PullRequestQuery, {
        owner: context.repo.owner,
        repo: context.repo.repo,
        label: process.env.LABEL_QUEUE,
    });

    // pulls is an array of PR information (with `number` and `timestamp` keys),
    // sorted oldest first.
    const pulls = queryResult.repository.labels.nodes.reduce((pulls, label) => {
        return pulls.concat(label.pullRequests.nodes.map((pr) => {
            const event = pr.timelineItems.nodes.reverse()
                .find((event) => event.label.name == process.env.LABEL_QUEUE);
            console.log(`Found event for PR#${pr.number}: queued at ${event.createdAt} by ${event.actor.login}`);
            return { number: pr.number, timestamp: Date.parse(event.createdAt) };
        }));
    }, []).sort((a, b) => a.timestamp - b.timestamp);

    for (let pr of pulls.slice(0, process.env.CAPACITY)) {
        console.log(`Queuing PR#${pr.number}`);
        github.issues.addLabels({
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
