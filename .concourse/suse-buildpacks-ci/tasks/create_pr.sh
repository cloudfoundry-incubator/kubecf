#!/usr/bin/env bash

# NEVER SET xtrace!
set -o errexit -o nounset

# Updates release information in values.yaml.
# It looks for a release like:
#
# suse-go-buildpack:
#   url: registry.suse.com/cap-staging
#   version: "1.9.4.1"
#   stemcell:
#     os: SLE_15_SP1
#     version: 23.1-7.0.0_374.gb8e8e6af
#   file: suse-go-buildpack/packages/go-buildpack-sle15/go-buildpack-sle15-v1.9.4.1-1.1-436eaf5d.zip

function update_buildpack_info() {

BUILDPACK_NAME=$1
KUBECF_VALUES=$2
BUILT_IMAGE=$3
NEW_FILE_NAME=$4

PYTHON_CODE=$(cat <<EOF 
#!/usr/bin/python3

import ruamel.yaml

# Adds ~ to the null values to preserve existing structure of values.yaml.
def represent_none(self, data):
    return self.represent_scalar(u'tag:yaml.org,2002:null', u'~')

# Replaces the filename at the end of the original 'file'.
def get_new_filename():
    new_file = values['releases']["${BUILDPACK_NAME}"]['file'].split("/")[:3]
    new_file.append("${NEW_FILE_NAME}")
    return "/".join(new_file)

yaml = ruamel.yaml.YAML()
yaml.preserve_quotes = True
yaml.representer.add_representer(type(None), represent_none)

# Breaking down the BUILT_IMAGE to retrieve individual values.
BUILT_IMAGE_LIST = "${BUILT_IMAGE}".split("/", 2)
NEW_URL = "/".join(BUILT_IMAGE_LIST[:2])
BUILT_IMAGE = BUILT_IMAGE_LIST[-1].split(":")[1].split("-")
NEW_STEMCELL_OS = BUILT_IMAGE[0]
NEW_STEMCELL_VERSION = "-".join(BUILT_IMAGE[1:3])
NEW_VERSION = BUILT_IMAGE[3]

with open("${KUBECF_VALUES}") as fp:
    values = yaml.load(fp)

values['releases']["${BUILDPACK_NAME}"]['url'] = NEW_URL
values['releases']["${BUILDPACK_NAME}"]['version'] = NEW_VERSION
values['releases']["${BUILDPACK_NAME}"]['stemcell']['os'] = NEW_STEMCELL_OS
values['releases']["${BUILDPACK_NAME}"]['stemcell']['version'] = NEW_STEMCELL_VERSION
values['releases']["${BUILDPACK_NAME}"]['file'] = get_new_filename()

with open("${KUBECF_VALUES}", 'w') as f:
    yaml.dump(values, f)

EOF
)

python3 -c "${PYTHON_CODE}"
}

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
BUILT_IMAGE=$(cat built_image/image)
NEW_FILE=$(tar -zxOf suse_final_release/*.tgz packages | tar -ztf - | grep zip | cut -d'/' -f3)

COMMIT_TITLE="Bump ${BUILDPACK_NAME} release to ${RELEASE_VERSION}"

# Update release in kubecf repo
cp -r kubecf/. updated-kubecf/
cd updated-kubecf

git pull
GIT_BRANCH_NAME="bump_${BUILDPACK_NAME}-$(date +%Y%m%d%H%M%S)"
git checkout -b "${GIT_BRANCH_NAME}"

update_buildpack_info "${BUILDPACK_NAME}" "${KUBECF_VALUES}" "${BUILT_IMAGE}" "${NEW_FILE}"

git commit "${KUBECF_VALUES}" -m "${COMMIT_TITLE}"

# Open a Pull Request
PR_MESSAGE=$(echo -e "${COMMIT_TITLE}")
hub pull-request --push --message "${PR_MESSAGE}" --base "${KUBECF_BRANCH}"
