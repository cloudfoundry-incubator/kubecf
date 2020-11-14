module.exports = async ({ github, context }) => {
    console.log(`Looking up runs for ${context.repo.owner}/${context.repo.repo}`);
    const promises = ["queued", "in_progress"]
        .map((status) => github.actions.listWorkflowRunsForRepo({
            owner: context.repo.owner,
            repo: context.repo.repo,
            status: status
        }));
    const runs = (await Promise.all(promises))
        .map((request) => request.data.workflow_runs)
        .reduce((a, v) => a.concat(v), [])
        .map((run) => run.id.toString());
    console.log(`Active/pending runs: ${runs.join(", ")}`);
    const selector = `.labels.ci and ([.labels.ci] | inside(${JSON.stringify(runs)}) | not)`;
    console.log(`Cluster filter selector: ${selector}`);
    return selector;
};
