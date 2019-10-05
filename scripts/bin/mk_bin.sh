#!/usr/bin/env bash

dir="$(pwd)"
parentdir="$(dirname "${dir}")"

source "${parentdir}/lib/functions.sh"

# --- Helper Functions ---------------------------------------------------

# Copies specified file to specified directory
copy_file() {
    if ! found_file ./"${1}"; then
        error_exit "ERROR: ./${1} not found"
    fi

    if ! found_dir "${2}"; then
        error_exit "ERROR: ${2} not found"
    fi

    echo_task "Copying/overwriting ./${1} to ${2}"
    cp -avf ./"${1}" "${2}/${1}"
}

# Create specified directory
create_dir() {
    if found_dir "${1}"; then
        echo_task "Already created directory: ${1}"
        return
    fi

    echo_task "Creating directory: ${1}"
    mkdir -pv "${1}"
}

# --- Main Function ------------------------------------------------------
main() {
    local -r bin_name="ssh_vm"
    local -r bin_dir="${HOME}/bin"

    echo_header "Test Directory: ${bin_dir}"
    create_dir "${bin_dir}"

    echo_header "Copying/overwriting file: ${bin_name}"
    copy_file "${bin_name}" "${bin_dir}"
}


main "$@"
