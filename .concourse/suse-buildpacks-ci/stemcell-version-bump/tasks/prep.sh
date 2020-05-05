#!/usr/bin/env bash

# NEVER SET xtrace!
set -o errexit -o nounset

function generate_releases_file() {

RELEASES_YAML=$1
KUBECF_VALUES_YAML=$2

PYTHON_CODE=$(cat <<EOF 
#!/usr/bin/python3

import ruamel.yaml
import requests
import hashlib

def fetch_sha1(url):
    file = requests.get(url)
    hash = hashlib.sha1()
    hash.update(file.content)
    return hash.hexdigest()

yaml = ruamel.yaml.YAML()
yaml.preserve_quotes = True

with open("${RELEASES_YAML}") as f1, open("${KUBECF_VALUES_YAML}") as f2:
    input_releases = yaml.load(f1)["releases"]
    values = yaml.load(f2)["releases"]

output_releases = []
for release in input_releases:
    output_release = {}
    output_release["name"] = release["name"]
    output_release["version"] = values[release["name_in_values_yaml"]]["version"]
    output_release["url"] = "https://s3.amazonaws.com/suse-final-releases/{}-release-{}.tgz".format(release["name"], output_release["version"])
    output_release["sha1"] = fetch_sha1(output_release["url"])
    output_releases.append(output_release)

with open("buildpacks_to_be_built/releases.yaml", 'w') as f:
    yaml.dump(output_releases, f)

EOF
)

python3 -c "${PYTHON_CODE}"
}

generate_releases_file "${RELEASES_YAML}" "${KUBECF_VALUES_YAML}"
