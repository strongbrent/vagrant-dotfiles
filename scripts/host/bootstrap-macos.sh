#!/usr/bin/env bash

dir="$(pwd)"
parentdir="$(dirname "${dir}")"

source "${parentdir}/lib/functions.sh"


# --- Helper Functions ---------------------------------------------------

# --- Main Function ------------------------------------------------------
main() {
    echo_header "Hello from macos"
}


main "$@"

