#!/usr/bin/env bash

# NEVER SET xtrace!
set -o errexit -o nounset

# Updates release information in sle15.yaml.
# It looks for a release like:
# stacks:
#   sle15:
#     releases:
#       suse-staticfile-buildpack:
#         version: "1.5.11"


if [[ -z "$GITHUB_TOKEN" ]]; then
    echo "GITHUB_TOKEN environment variable not set"
    exit 1
fi

# Setup git
mkdir -p ~/.ssh
ssh-keyscan -t rsa github.com | tee ~/.ssh/known_hosts | ssh-keygen -lf -
echo -e "${GITHUB_PRIVATE_KEY}" | sed -E 's/(-+(BEGIN|END) OPENSSH PRIVATE KEY-+) *| +/\1\n/g' >~/.ssh/id_ecdsa
chmod 0600 ~/.ssh/id_ecdsa

git config --global user.email "$GIT_MAIL"
git config --global user.name "$GIT_USER"

RELEASE_VERSION=$(cat suse_final_release/version)

COMMIT_TITLE="feat: Bump ${BUILDPACK_NAME} release to ${RELEASE_VERSION}"

# Update release in kubecf repo
cp -r kubecf/. updated-kubecf/
cd updated-kubecf

git pull
GIT_BRANCH_NAME="bump_${BUILDPACK_NAME}-$(date +%Y%m%d%H%M%S)"
git checkout -b "${GIT_BRANCH_NAME}"

perl -i -0pe "s/      ${BUILDPACK_NAME}:\n        version: \"[\d.]+\"/      ${BUILDPACK_NAME}:\n        version: \"${RELEASE_VERSION}\"/" "${KUBECF_VALUES}"

git commit "${KUBECF_VALUES}" -m "${COMMIT_TITLE}"

# Open a Pull Request
PR_MESSAGE=$(echo -e "${COMMIT_TITLE}")
hub pull-request --push --message "${PR_MESSAGE}" --base "${KUBECF_BRANCH}"
