#!/usr/bin/env bash

# Global Variables
export DEBIAN_FRONTEND=noninteractive
BASHRC="${HOME}/.bashrc"
ZSHRC="${HOME}/.zshrc"

# Global Array
shell_envs=(
    "${BASHRC}"
    "${ZSHRC}"
)


# --- Helper Functions ---------------------------------------------------

# DESC: Prompts the user with Go/No-go question
# ARGS: $1 (OPT): string representing the question
#                 - default: Are you sure? [y/N]
# OUT:  true  -> if Y
#       false -> if N
confirm() {
    # call with a prompt string or use a default
    read -r -p "${1:-Are you sure? [y/N]} " response
    case "$response" in
        [yY][eE][sS]|[yY])
            true
            ;;
        *)
            false
            ;;
    esac
}

# DESC: Prints a header statement to standard out
# ARGS: S1 (OPT): message string
# OUT: NONE
echo_header() {
    # Function variables/constants
    local -r pre="===>"
    local -r msg="${1:-Empty Header}"

    # Run Commands
    echo ""
    echo "${pre} ${msg}"
}

# DESC: Prints a task description
# ARGS: $1 (OPT): message string
# OUT:  NONE
echo_task() {
    # Function variables/constants
    local -r pre="....."
    local -r msg="${1:-Empty task}"

    # Run commands
    echo "${pre} ${msg}"
}

# DESC: Safe script exit (copy to libs)
# ARGS: $1 (OPT): Error message string
# OUT:  1
error_exit() {
    echo "${1:-UNKNOWN ERROR}"

    # handle exits from shell or function but don't exit interactive shell
    [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1
}

# DESC: Checks to see if a command exists
# ARGS: $1 (REQ): name of command
# OUT:  0  -> if found
#       !0 -> if not found
found_cmd() {
    command -v "${1}" &>/dev/null
}

# DESC: Checks to see if a directory exists
# ARGS: $1 (REQ): name of directory
# OUT:  0  -> if found
#       !0 -> if not found
found_dir() {
    test -d "${1}" &>/dev/null
}

# DESC: Checks to see if a file exists
# ARGS: $1 (REQ): name of file
# OUT:  0  -> if found
#       !0 -> if not found
found_file() {
    test -f "${1}" &>/dev/null
}

# DESC: Replaces a line (in place) in a specified file with specified text
# ARGS: $1 (REQ): original line of text
#       $2 (REQ): new line of text
#       $3 (REQ): specified file
# OUT:  NONE
replace_line() {
    sed -i "s/${1}/${2}/g" "${3}"
}

