# shellcheck shell=bash
# shellcheck disable=SC2034

# Temporary files (e.g. downloads) should go to $TEMP_DIR.
TEMP_DIR="${PWD}/output/tmp"
mkdir -p "${TEMP_DIR}"

# All downloaded tools will be installed into $TOOLS_DIR.
TOOLS_DIR="${PWD}/output/bin"
mkdir -p "${TOOLS_DIR}"

# UNAME should be DARWIN, LINUX, or WINDOWS.
UNAME="$(uname | tr "[:lower:]" "[:upper:]")"

# Source all tool definitions.
TOOLS=()
# shellcheck disable=SC2044
for TOOL in $(find scripts/tools/*.sh); do
    # shellcheck disable=SC1090
    source "${TOOL}"
done

# Sort tools alphabetically and remove duplicates (there shouldn't be any).
# shellcheck disable=SC2207
TOOLS=($(printf '%s\n' "${TOOLS[@]}" | sort | uniq))

# require_tools makes sure all required tools are available. If the current version
# is too old (or doesn't match the required version exactly when PINNED_TOOLS is set),
# then the tool is downloaded and installed into $TOOLS_DIR.
function require_tools {
    local status
    for tool in "$@"; do
        if ! status=$(tool_status "${tool}"); then
            tool_install "${tool}"

            if ! status="$(tool_status "${tool}")"; then
                red "Could not install ${tool}"
                die "${status}"
            fi
        fi
        # Make sure additional prerequisites for the tool are also available.
        # In this case we *want* word-splitting.
        # shellcheck disable=SC2046
        require_tools $(var_lookup "${tool}_requires")
    done
}

# tool_status checks the current installation status of a single tool. It return
# a status string, that can be displayed to the user. The return value is either 0
# when an acceptable version of the tool is available, or 1 when the correct
# version needs to be installed.
function tool_status {
    local tool=$1
    local version
    local rc=0
    local status

    version="$(tool_version "${tool}")"
    if [[ "${version}" =~ ^installed|internal|missing$ ]]; then
        if [ "${version}" = "missing" ]; then
            rc=1
        fi
        status="is ${version}"
    else
        status="version is ${version}"
        local minimum
        minimum="$(var_lookup "${tool}_version")"
        if [ -n "${minimum}" ]; then
            case "$(ruby -e "puts Gem::Version.new('${minimum}') <=> Gem::Version.new('${version}')")" in
                -1)
                    status="${status} (newer than ${minimum})"
                    # For PINNED_TOOLS only an exact match is a success (if there is a download URL).
                    if [[ -n "${PINNED_TOOLS:-}" && -n "$(var_lookup "${tool}_url_${UNAME}")" ]]; then
                        rc=1
                    fi
                    ;;
                0)
                    # PINNED_TOOLS *must* be installed in $TOOLS_DIR
                    if [[ -n "${PINNED_TOOLS:-}" && ! -x "${TOOLS_DIR}/${tool}" ]]; then
                        status="${status} (but not installed in ${TOOLS_DIR})"
                        rc=1
                    fi
                    ;;
                1|*)
                    status="${status} (older than ${minimum})"
                    rc=1
                    ;;
            esac
        fi
    fi
    status="${tool} ${status}"

    if [ $rc -eq 0 ]; then
        status="$(green "${status}")"
    else
        status="$(red "${status}")"
    fi
    echo "${status}"
    return ${rc}
}

# tool_version returns the semantic version of the installed tool. I will
# return "internal" for tools implemented as aliases/functions, "missing"
# for tools that cannot be found, and "installed" if the version cannot be
# determined. It is a fatal error if the version cannot be determined for
# a tool that defines a minimum required version.
function tool_version {
    local tool=$1
    local version=""
    local tool_type
    local minimum_version

    tool_type="$(type -t "${tool}")"
    minimum_version="$(var_lookup "${tool}_version")"

    # (Maybe) determine installed version of the tool.
    if [ -z "${tool_type}" ]; then
        echo "missing"
    else
        # Call custom tool version function, if defined.
        if [ -n "$(type -t "${tool}_version")" ]; then
            version="$("${tool}_version")"
        # only call default "$tool version" command if minimum version is defined.
        elif [[ "${tool_type}" = "file" && -n "${minimum_version}" ]]; then
            version="$("${tool}" version)"
        fi

        # Version number must have at least a single dot.
        if [[ "${version}" =~ [0-9]+(\.[0-9]+)+ ]]; then
            echo "${BASH_REMATCH[0]}"
        else
            if [ -n "${minimum_version}" ]; then
                die "Cannot determine '${tool}' version (requires ${minimum_version})"
            fi
            case "${tool_type}" in
                file)
                    echo "installed"
                    ;;
                '')
                    echo "missing"
                    ;;
                *)
                    echo "internal"
                    ;;
            esac
        fi
    fi
}

function tool_install {
    local tool=$1
    local url
    local version
    version="$(var_lookup "${tool}_version")"

    blue "Installing ${tool}"

    # XXX (require_tools is not reentrant) require_tools file gzip sha256sum

    url="$(var_lookup "${tool}_url_${UNAME}")"
    if [ -z "${url}" ]; then
        die "Can't find URL for ${tool}-${version}"
    fi

    local output="${TEMP_DIR}/output"
    curl -s -L "${url/\{version\}/${version}}" -o "${output}"

    # XXX check SHA256 if defined

    local install_location="${TOOLS_DIR}/${tool}"
    # Keep previous version in case installation fails.
    if [ -f "${install_location}" ]; then
        mv "${install_location}" "${install_location}.prev"
    fi

    if [[ "$(file "${output}")" =~ gzip ]]; then
        mv "${output}" "${output}.gz"
        gzip -d "${output}.gz"
    fi

    local file_type
    file_type="$(file "${output}")"
    case "${file_type}" in
        *executable*)
            mv "${output}" "${install_location}"
            ;;
        *tar*)
            local outdir="${TEMP_DIR}/outdir"
            mkdir -p "${outdir}"
            tar xf "${output}" -C "${outdir}"
            find "${outdir}" -name "${tool}" -exec cp {} "${install_location}" \;
            if [ -f "${install_location}" ]; then
                rm -rf "${output}" "${outdir}"
            fi
            ;;
        *)
            die "Unsupported file type of ${output}:\n${file_type}"
            ;;
    esac

    if [ -f "${install_location}" ]; then
        chmod +x "${install_location}"
    else
        if [ -f "${install_location}.prev" ]; then
            mv "${install_location}.prev" "${install_location}"
        fi
        die "Installation of ${tool} failed (previous version may have been restored)"
    fi
}
