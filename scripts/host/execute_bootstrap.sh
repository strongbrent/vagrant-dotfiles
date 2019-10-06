#!/usr/bin/env bash

dir="$(pwd)"
parentdir="$(dirname "${dir}")"

source "${parentdir}/lib/functions.sh"

# Global Variables
export OS_TYPE=$(uname)


# --- Helper Functions ---------------------------------------------------

# DESC: Sets the OS name and version
# ARGS: ENV OS_TYPE: OS type (Linux or Darwin)
# OUT:  Exports ID and VERSION_ID variables
get_distro_info() {
    # Function vars/constants
    local -r linux_dist_info="/etc/os-release"

    # Run commands
    case "${OS_TYPE}" in
        Darwin)
            export ID="macos"
            export VERSION_ID=$(sw_vers | grep ProductVersion | awk '{print $2}')
            ;;
        Linux)
            if [[ ! -f ${linux_dist_info} ]]; then
                error_exit "ERROR: ${linux_dist_info} does not exist"
            else
                source ${linux_dist_info}
                export ID
                export VERSION_ID
                if [[ "${ID}" == "ubuntu" ]]; then
                    export ID_LIKE
                fi
            fi
            ;;
        *)
            error_exit "ERROR: Unknown OS"
            ;;
    esac
}


# --- Main Function ------------------------------------------------------
main() {
    local bootstrap=""

    echo_header "Processing: OS and Distro Information"
    get_distro_info
    export OS_DISTRO="${ID}-${VERSION_ID}"
    echo_task "Found: ${OS_DISTRO}"

    echo_header "Initializing Bootstrap File For: ${ID}"
    case "${ID}" in
        ubuntu)
            bootstrap="bootstrap-ubuntu.sh"
            ;;
        macos)
            bootstrap="bootstrap-macos.sh"
            ;;
        *)
            error_exit "ERROR: Unknown OS"
            ;;
    esac

    if ! found_file ./"${bootstrap}"; then
        error_exit "ERROR: File not found - ${bootstrap}"
    fi

    echo_task "Executing Bootstrap File: ${bootstrap}"
    ./${bootstrap}
}

main "$@"

