#!/usr/bin/env bash

dir="$(pwd)"
parentdir="$(dirname "${dir}")"

source "${parentdir}/lib/functions.sh"

# Global Variables
export OS_TYPE=$(uname)


# --- Helper Functions ---------------------------------------------------

# DESC: Processes script command line arguments
# ARGS: $@  : all command line args
# OUT:  sets: must_confirm
#             git_branch
check_cli_args() {
    while getopts ":hyb:" arg; do
        case ${arg} in
            h)
                # Display help
                usage
                exit 0
                ;;
            y)
                # Skip confirmation to proceed
                must_confirm="yes"
                ;;
            \?)
                usage
                error_exit "ERROR: incorrect CLI arg"
                ;;
        esac
    done
    shift $((OPTIND -1))
}

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

# DESC: Displays help to the user
# ARGS: $0 (Special Param): Name of the shell script
# OUT: NONE
usage() {
    # Run commands
    echo ""
    echo "Usage: $0 [-h] [-y] [-b <git_branch_name>]"
    echo "       -h: help   - prints this message"
    echo "       -y: yes    - auto-install without prompt"
    echo ""
}


# --- Main Function ------------------------------------------------------
main() {
    # main function variables
    must_confirm="no"
    local bootstrap=""

    # Check CLI args
    check_cli_args "$@"

    ### Get confirmation to proceed ###
    if [[ ! ${must_confirm} == "yes" ]]; then
        echo_header "Getting confirmation to proceed"
        echo "Warning. This script installs software and overwrite files in your HOME directory."
        if ! confirm "Do you with to continue? [y/N] "; then
            echo "Good bye."
            exit 0
        fi
    fi
    ### Get confirmation to proceed ###

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
