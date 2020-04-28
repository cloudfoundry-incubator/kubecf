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

KUBECF_VALUES=$1
BUILT_IMAGES=$2

PYTHON_CODE=$(cat <<EOF 
#!/usr/bin/python3

import ruamel.yaml

# Adds ~ to the null values to preserve existing structure of values.yaml.
def represent_none(self, data):
    return self.represent_scalar(u'tag:yaml.org,2002:null', u'~')

yaml = ruamel.yaml.YAML()
yaml.preserve_quotes = True
yaml.representer.add_representer(type(None), represent_none)

with open("${BUILT_IMAGES}") as built_images, open("${KUBECF_VALUES}") as kubecf_values:
    values = yaml.load(kubecf_values)
    for built_image in built_images:
        # Breaking down the BUILT_IMAGE to retrieve individual values.
        built_image_splitted = built_image.split("/", 2)
        BUILDPACK_NAME = built_image_splitted[-1].split(":")[0]
        built_image_splitted2 = built_image_splitted[-1].split(":")[1].split("-")
        NEW_STEMCELL_OS = built_image_splitted2[0]
        NEW_STEMCELL_VERSION = "-".join(built_image_splitted2[1:3])
        
        # Updating new values in kubecf values yaml.
        values['releases'][BUILDPACK_NAME]['stemcell']['os'] = NEW_STEMCELL_OS
        values['releases'][BUILDPACK_NAME]['stemcell']['version'] = NEW_STEMCELL_VERSION

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

stemcell_version="$(cat s3.stemcell-version/"${STEMCELL_VERSIONED_FILE##*/}")"
COMMIT_TITLE="Bump stemcell version for SUSE buildpacks to ${stemcell_version}"

images_dir=$(pwd)/"${BUILT_IMAGES}"

# Update release in kubecf repo
cp -r kubecf/. updated-kubecf/
cd updated-kubecf

git pull
GIT_BRANCH_NAME="bump_${stemcell_version}-$(date +%Y%m%d%H%M%S)"
git checkout -b "${GIT_BRANCH_NAME}"

update_buildpack_info "${KUBECF_VALUES}" "${images_dir}"

git commit "${KUBECF_VALUES}" -m "${COMMIT_TITLE}"

# Open a Pull Request
PR_MESSAGE=$(echo -e "${COMMIT_TITLE}")
hub pull-request --push --message "${PR_MESSAGE}" --base "${KUBECF_BRANCH}"
